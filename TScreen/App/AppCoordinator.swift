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
            window.title = "Cài đặt TScreen"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func run() {
        guard !isSelecting else { return }
        isSelecting = true
        Task {
            let selected = await RegionSelector().select()
            isSelecting = false
            guard let region = selected else { return }
            let model = ViewerModel()
            let viewer = ViewerWindowController()
            // Đo thời gian từng bước để biết bước nào chậm.
            let clock = ContinuousClock()
            var mark = clock.now
            @MainActor func lap(_ name: String) {
                let seconds = (clock.now - mark) / .seconds(1)
                mark = clock.now
                model.timings.append(String(format: "%@ %.2fs", name, seconds))
            }
            do {
                let image = try await ScreenCapturer.capture(region)
                lap("Chụp")
                model.original = image
                model.status = .working("Đang nhận diện chữ…")
                viewer.show(model, near: region)

                let blocks = try await TextRecognizer.recognize(image)
                lap("OCR (\(blocks.count) khối)")
                guard !blocks.isEmpty else {
                    model.status = .failed("Không tìm thấy chữ trong vùng đã chụp.")
                    return
                }
                let source = Self.detectLanguage(blocks.map(\.text).joined(separator: "\n"))

                // Bước dịch + vẽ tách riêng để nút "Thử lại" gọi lại API mà không cần chụp/OCR lại.
                @MainActor func translateAndCompose() async {
                    let settings = AppSettings.current
                    model.retry = nil
                    mark = clock.now
                    switch settings.engine {
                    case "claude": model.status = .working("Đang gửi chữ tới Claude để dịch…")
                    case "openai": model.status = .working("Đang gửi chữ tới OpenAI để dịch…")
                    default: model.status = .working("Đang dịch trên máy…")
                    }
                    let texts: [String]
                    do {
                        texts = try await makeTranslator(settings)
                            .translate(blocks.map(\.text), from: source, to: settings.targetLanguage)
                    } catch {
                        model.status = .failed(error.localizedDescription)
                        if ["openai", "claude"].contains(settings.engine) {
                            model.retry = { Task { await translateAndCompose() } }
                        }
                        return
                    }
                    lap("Dịch (\(settings.engine))")
                    let scale = CGFloat(image.width) / region.width
                    model.translated = ImageComposer.compose(image, blocks: blocks, translations: texts,
                                                             scale: scale, fontName: settings.fontName)
                    lap("Vẽ")
                    model.translatedText = texts.joined(separator: "\n")
                    model.status = .done
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
