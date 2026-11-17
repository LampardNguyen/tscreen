import AppKit
import SwiftUI
import NaturalLanguage

/// Chạy pipeline: chọn vùng → chụp → OCR → nhận diện ngôn ngữ → dịch → vẽ → viewer.
@MainActor
final class AppCoordinator {
    static let shared = AppCoordinator()
    private var isSelecting = false
    private var settingsWindow: NSWindow?

    func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 460, height: 420), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            settingsWindow = window
        }
        // Gán tiêu đề mỗi lần mở vì cửa sổ được dùng lại, ngôn ngữ giao diện có thể đã đổi.
        settingsWindow?.title = L("settings.windowTitle")
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func run() {
        guard !isSelecting else { return }
        isSelecting = true
        Task {
            let model = ViewerModel()
            let viewer = ViewerWindowController()
            let selected: (region: CGRect, image: CGImage)?
            do {
                selected = try await RegionSelector().select()
            } catch {
                isSelecting = false
                model.status = .failed(error.localizedDescription)
                let screen = NSScreen.main?.frame ?? .zero
                viewer.show(model, near: CGRect(x: screen.midX - 210, y: screen.midY - 45, width: 420, height: 90))
                return
            }
            isSelecting = false
            guard let (region, image) = selected else { return }
            // Đo thời gian từng bước để biết bước nào chậm.
            let clock = ContinuousClock()
            var mark = clock.now
            @MainActor func lap(_ name: String) {
                let seconds = (clock.now - mark) / .seconds(1)
                mark = clock.now
                model.timings.append(String(format: "%@ %.2fs", name, seconds))
            }
            do {
                model.original = image
                model.status = .working(L("status.recognizing"))
                viewer.show(model, near: region)

                let blocks = try await TextRecognizer.recognize(image)
                lap(L("timing.ocr", blocks.count))
                guard !blocks.isEmpty else {
                    model.status = .failed(L("status.noText"))
                    return
                }
                let source = Self.detectLanguage(blocks.map(\.text).joined(separator: "\n"))
                // Id bản ghi lịch sử của lần chụp này; "Thử lại" thành công thì thay bản cũ thay vì thêm bản mới.
                var historyID: UUID?

                // Bước dịch + vẽ tách riêng để nút "Thử lại" gọi lại API mà không cần chụp/OCR lại.
                @MainActor func translateAndCompose() async {
                    let settings = AppSettings.current
                    model.retry = nil
                    model.errorDetail = nil
                    mark = clock.now
                    switch settings.engine {
                    case "claude": model.status = .working(L("status.sending", "Claude"))
                    case "openai": model.status = .working(L("status.sending", "OpenAI"))
                    case "custom": model.status = .working(L("status.sending", L("settings.customAPI")))
                    default: model.status = .working(L("status.translatingOnDevice"))
                    }
                    let texts: [String]
                    do {
                        texts = try await makeTranslator(settings)
                            .translate(blocks.map(\.text), from: source, to: settings.targetLanguage)
                    } catch {
                        model.status = .failed(error.localizedDescription)
                        model.errorDetail = (error as? TranslationError)?.detail
                        if ["openai", "claude", "custom"].contains(settings.engine) {
                            model.retry = { Task { await translateAndCompose() } }
                        }
                        return
                    }
                    lap(L("timing.translate", settings.engine))
                    let scale = CGFloat(image.width) / region.width
                    model.translated = ImageComposer.compose(image, blocks: blocks, translations: texts,
                                                             scale: scale, fontName: settings.fontName)
                    lap(L("timing.render"))
                    model.translatedText = texts.joined(separator: "\n")
                    model.status = .done
                    if HistoryStore.isEnabled, let translated = model.translated {
                        if let historyID { HistoryStore.shared.delete(historyID) }
                        // Lưu lịch sử lỗi (đầy đĩa, quyền) không được làm hỏng kết quả đang hiện, chỉ ghi log.
                        do {
                            historyID = try HistoryStore.shared.add(image: translated, size: region.size, engine: settings.engine,
                                                                    sourceText: blocks.map(\.text).joined(separator: "\n"),
                                                                    translatedText: model.translatedText)
                            // Gắn id để mở item này từ lịch sử thì kích hoạt lại viewer đang mở thay vì tạo mới.
                            viewer.historyID = historyID
                        } catch {
                            NSLog("TScreen: không lưu được lịch sử: %@", error.localizedDescription)
                        }
                    }
                    NSLog("TScreen timings: %@", model.timings.joined(separator: " · "))
                }
                await translateAndCompose()
            } catch {
                model.status = .failed(error.localizedDescription)
                if model.original == nil { viewer.show(model, near: region) }
            }
        }
    }

    static func detectLanguage(_ text: String) -> Locale.Language? {
        NLLanguageRecognizer.dominantLanguage(for: text).map { Locale.Language(identifier: $0.rawValue) }
    }
}
