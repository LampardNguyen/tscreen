import AppIntents
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Nhận ảnh chụp màn hình từ Phím tắt → OCR → dịch → trả ảnh đã vẽ chữ dịch (không lưu lại).
/// Phím tắt gợi ý: Chụp ảnh màn hình → Dịch bằng TScreen → Xem nhanh, gán vào AssistiveTouch.
struct TranslateScreenshotIntent: AppIntent {
    static let title: LocalizedStringResource = "Dịch bằng TScreen"
    static let description = IntentDescription("Nhận diện chữ trong ảnh và vẽ bản dịch đè lên ảnh.")
    static let openAppWhenRun = false

    @Parameter(title: "Ảnh", supportedContentTypes: [.image])
    var image: IntentFile

    // Tham số nằm ngay trong câu → Phím tắt tự nối ảnh từ bước trước và cho chọn biến khi chạm vào.
    static var parameterSummary: some ParameterSummary {
        Summary("Dịch \(\.$image) bằng TScreen")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        guard let source = CGImageSourceCreateWithData(image.data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw TranslationError(L("ios.error.badImage"))
        }
        let blocks = try await TextRecognizer.recognize(cgImage)
        guard !blocks.isEmpty else { throw TranslationError(L("status.noText")) }
        let settings = AppSettings.current
        let texts = try await makeTranslator(settings).translate(
            blocks.map(\.text), from: detectLanguage(blocks.map(\.text).joined(separator: "\n")), to: settings.targetLanguage)
        // Ảnh chụp màn hình có pixel = point × scale của màn hình (iPhone thường @3x).
        let scale = await UIScreen.main.scale
        let output = ImageComposer.compose(cgImage, blocks: blocks, translations: texts, scale: scale, fontName: settings.fontName)
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw TranslationError(L("ios.error.badImage"))
        }
        CGImageDestinationAddImage(dest, output, nil)
        CGImageDestinationFinalize(dest)
        return .result(value: IntentFile(data: data as Data, filename: "TScreen.png", type: .png))
    }
}

struct TScreenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: TranslateScreenshotIntent(),
                    phrases: ["Dịch màn hình bằng \(.applicationName)"],
                    shortTitle: "Dịch ảnh",
                    systemImageName: "character.bubble")
    }
}
