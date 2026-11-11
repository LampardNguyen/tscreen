import XCTest
@testable import TScreen

final class TScreenTests: XCTestCase {
    func testJoinLines() {
        XCTAssertEqual(TextBlock.joinLines(["Hello", "world"]), "Hello world")
        XCTAssertEqual(TextBlock.joinLines(["こんにち", "は世界"]), "こんにちは世界")
        XCTAssertEqual(TextBlock.joinLines(["日本語", "English"]), "日本語 English")
    }

    /// Ảnh 20×10 nền trắng, có một vạch "chữ" xanh đậm ở giữa.
    private func sampleBitmap() -> Bitmap {
        var data = [UInt8](repeating: 255, count: 20 * 10 * 4)
        for y in 4...5 { for x in 5...14 {
            let i = (y * 20 + x) * 4
            data[i] = 10; data[i + 1] = 20; data[i + 2] = 200
        } }
        return Bitmap(width: 20, height: 10, data: data)
    }

    func testBackgroundColorIsBorderMedian() {
        XCTAssertEqual(sampleBitmap().backgroundColor(in: CGRect(x: 0, y: 0, width: 20, height: 10)), RGB(r: 255, g: 255, b: 255))
    }

    func testTextColorPicksInk() {
        let bitmap = sampleBitmap()
        let color = bitmap.textColor(in: CGRect(x: 0, y: 0, width: 20, height: 10), background: RGB(r: 255, g: 255, b: 255))
        XCTAssertEqual(color, RGB(r: 10, g: 20, b: 200))
    }

    func testTextColorFallsBackOnLowContrast() {
        let flat = Bitmap(width: 4, height: 4, data: [UInt8](repeating: 30, count: 64))
        XCTAssertEqual(flat.textColor(in: CGRect(x: 0, y: 0, width: 4, height: 4), background: RGB(r: 30, g: 30, b: 30)),
                       RGB(r: 255, g: 255, b: 255))
    }

    func testFitSize() {
        let short = TextFitter.fitSize("Hi", fontName: "", in: CGSize(width: 400, height: 40), minSize: 8, maxSize: 30)
        XCTAssertEqual(short, 30)
        let text = "Đây là một câu khá dài cần phải xuống dòng và thu nhỏ để vừa khung"
        let box = CGSize(width: 150, height: 40)
        let size = TextFitter.fitSize(text, fontName: "", in: box, minSize: 8, maxSize: 30)
        XCTAssertLessThan(size, 30)
        XCTAssertGreaterThanOrEqual(size, 8)
        XCTAssertLessThanOrEqual(TextFitter.measure(text, fontName: "", size: size, width: box.width).height, box.height)
    }

    func testClaudeParse() throws {
        let json = #"{"content":[{"type":"text","text":"```json\n[\"Xin chào\",\"Thế giới\"]\n```"}]}"#
        XCTAssertEqual(try ClaudeTranslator.parse(Data(json.utf8), count: 2), ["Xin chào", "Thế giới"])
        XCTAssertThrowsError(try ClaudeTranslator.parse(Data(json.utf8), count: 3))
    }

    func testOpenAIParse() throws {
        let json = #"{"choices":[{"message":{"role":"assistant","content":"[\"Xin chào\",\"Thế giới\"]"}}]}"#
        XCTAssertEqual(try OpenAITranslator.parse(Data(json.utf8), count: 2), ["Xin chào", "Thế giới"])
        XCTAssertThrowsError(try OpenAITranslator.parse(Data(json.utf8), count: 1))
    }

    func testAPIErrorShowsOnlyProviderMessage() {
        let body = Data(#"{"error":{"message":"Incorrect API key","type":"auth"},"debug":"internal-detail"}"#.utf8)
        let text = LLMTranslation.apiError("OpenAI", status: 401, data: body).errorDescription ?? ""
        XCTAssertTrue(text.contains("401") && text.contains("Incorrect API key"), text)
        XCTAssertFalse(text.contains("internal-detail"), text)
    }

    /// OCR thật trên ảnh tự vẽ rồi ghép chữ dịch vào.
    func testRecognizeAndCompose() async throws {
        let w = 800, h = 240
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(srgbRed: 0.1, green: 0.12, blue: 0.2, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        for (text, y) in [("The quick brown fox jumps over the lazy dog", 150.0), ("設定を保存しました", 60.0)] {
            ctx.textPosition = CGPoint(x: 30, y: y)
            CTLineDraw(CTLineCreateWithAttributedString(
                TextFitter.attributed(text, font: TextFitter.font("", size: 32), color: white)), ctx)
        }
        let image = ctx.makeImage()!

        let blocks = try await TextRecognizer.recognize(image)
        let all = blocks.map(\.text).joined(separator: " ")
        XCTAssertTrue(all.contains("quick brown fox"), all)
        XCTAssertTrue(all.contains("設定"), all)

        let out = ImageComposer.compose(image, blocks: blocks, translations: blocks.map { _ in "Bản dịch tiếng Việt thử nghiệm" },
                                        scale: 2, fontName: "")
        XCTAssertEqual(out.width, w)
        if let dir = ProcessInfo.processInfo.environment["TSCREEN_TEST_OUTPUT"] {
            try NSBitmapImageRep(cgImage: out).representation(using: .png, properties: [:])!
                .write(to: URL(fileURLWithPath: dir).appendingPathComponent("composed.png"))
        }
    }
}
