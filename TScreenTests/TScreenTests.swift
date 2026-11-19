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
        // Đường chính: tool_use; đường dự phòng: text có code fence.
        let tool = #"{"content":[{"type":"tool_use","name":"submit_translations","input":{"2":"Thế giới","1":"Xin chào"}}],"stop_reason":"tool_use"}"#
        XCTAssertEqual(try ClaudeTranslator.parse(Data(tool.utf8), input: ["Hello", "World"]), ["Xin chào", "Thế giới"])
        let text = #"{"content":[{"type":"text","text":"```json\n{\"1\":\"Xin chào\",\"2\":\"Thế giới\"}\n```"}]}"#
        XCTAssertEqual(try ClaudeTranslator.parse(Data(text.utf8), input: ["Hello", "World"]), ["Xin chào", "Thế giới"])
    }

    func testOpenAIParse() throws {
        let json = #"{"choices":[{"message":{"role":"assistant","content":"{\"1\":\"Xin chào\",\"2\":\"Thế giới\"}"}}]}"#
        XCTAssertEqual(try OpenAITranslator.parse(Data(json.utf8), input: ["Hello", "World"]), ["Xin chào", "Thế giới"])
    }

    /// Input giữ thứ tự id số (không phải "1","10","2"); schema bắt buộc đủ mọi id.
    func testKeyedInputAndSchema() throws {
        let texts = (1...10).map { "t\($0)" }
        XCTAssertTrue(try LLMTranslation.keyedInput(texts).hasPrefix(#"{"1":"t1","2":"t2","#))
        XCTAssertEqual(LLMTranslation.schema(count: 3)["required"] as? [String], ["1", "2", "3"])
    }

    /// Thiếu id (model gộp câu bị OCR cắt) thì giữ chữ gốc thay vì báo lỗi cả lô.
    func testMissingIdKeepsOriginal() throws {
        XCTAssertEqual(try LLMTranslation.parseKeyed(#"{"1":"Câu đầy đủ","3":"C"}"#, input: ["A1", "A2", "B"]),
                       ["Câu đầy đủ", "A2", "C"])
    }

    /// Mỗi loại lỗi định dạng có thông báo riêng và kèm chi tiết chứa phản hồi gốc.
    func testParseErrorKinds() {
        func message(_ block: () throws -> Any) -> (String, String) {
            do { _ = try block(); return ("", "") } catch let e as TranslationError {
                return (e.errorDescription ?? "", e.detail ?? "")
            } catch { return ("", "") }
        }
        let cut = #"{"content":[{"type":"text","text":"{\"1\":\"a\","}],"stop_reason":"max_tokens"}"#
        XCTAssertTrue(message { try ClaudeTranslator.parse(Data(cut.utf8), input: ["A", "B"]) }.0.contains("bị cắt"))
        let length = #"{"choices":[{"message":{"content":"{\"1\":\"a\""},"finish_reason":"length"}]}"#
        XCTAssertTrue(message { try OpenAITranslator.parse(Data(length.utf8), input: ["A", "B"]) }.0.contains("bị cắt"))

        XCTAssertTrue(message { try LLMTranslation.parseKeyed("xin lỗi", input: ["A"]) }.0.contains("không trả về object"))
        XCTAssertTrue(message { try LLMTranslation.parseKeyed(#"{"1" "a"}"#, input: ["A"]) }.0.contains("JSON hỏng"))
        let (text, detail) = message { try LLMTranslation.parseKeyed(#"{"x":"y"}"#, input: ["A", "B"]) }
        XCTAssertTrue(text.contains("sai id"))
        XCTAssertTrue(detail.contains("1. A") && detail.contains("2. B") && detail.contains(#"{"x":"y"}"#))
    }

    /// Lưu → đọc lại từ đĩa → tìm (không dấu) → xoá → tự xoá bản cũ khi vượt giới hạn.
    @MainActor
    func testHistoryStore() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let ctx = CGContext(data: nil, width: 40, height: 20, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let image = ctx.makeImage()!

        let store = HistoryStore(directory: dir, limit: 2)
        let first = try store.add(image: image, size: CGSize(width: 40, height: 20), engine: "openai", sourceText: "決済", translatedText: "Thanh toán")
        try store.add(image: image, size: CGSize(width: 40, height: 20), engine: "claude", sourceText: "Hello", translatedText: "Xin chào")
        XCTAssertEqual(HistoryStore(directory: dir).entries.map(\.translatedText), ["Xin chào", "Thanh toán"])
        XCTAssertNotNil(store.image(first))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.thumbnailURL(first).path))

        XCTAssertEqual(HistoryStore.filter(store.entries, query: "thanh toan").map(\.id), [first])
        XCTAssertEqual(HistoryStore.filter(store.entries, query: "決済").map(\.id), [first])
        XCTAssertEqual(HistoryStore.filter(store.entries, query: " ").count, 2)

        // Đặt tiêu đề: lưu xuống đĩa, tìm được theo tiêu đề; chuỗi trắng = bỏ tiêu đề.
        try store.rename(first, title: "  Hoá đơn tháng 11 ")
        XCTAssertEqual(HistoryStore(directory: dir).entries.first { $0.id == first }?.title, "Hoá đơn tháng 11")
        XCTAssertEqual(HistoryStore.filter(store.entries, query: "thang 11").map(\.id), [first])
        try store.rename(first, title: "   ")
        XCTAssertNil(store.entries.first { $0.id == first }?.title)

        try store.add(image: image, size: .zero, engine: "apple", sourceText: "", translatedText: "Mới")
        XCTAssertEqual(store.entries.map(\.translatedText), ["Mới", "Xin chào"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.folder(first).path))

        store.delete(store.entries[0].id)
        XCTAssertEqual(store.entries.map(\.translatedText), ["Xin chào"])
        store.deleteAll()
        XCTAssertTrue(HistoryStore(directory: dir).entries.isEmpty)
    }

    func testCustomEngineUsesOwnKeyAndName() async {
        let translator = makeTranslator(AppSettings(
            targetLanguage: Locale.Language(identifier: "vi"), engine: "custom", claudeModel: "", openAIModel: "",
            openAIReasoningEffort: "", customURL: "https://example.test/v1/", customModel: "m",
            customReasoningEffort: "", fontName: ""))
        let custom = translator as? OpenAITranslator
        XCTAssertEqual(custom?.endpoint, "https://example.test/v1/chat/completions")
        XCTAssertEqual(chatCompletionsURL(base: " https://example.test/v1 "), "https://example.test/v1/chat/completions")
        XCTAssertEqual(custom?.keychainKey, "customAPIKey")
        XCTAssertEqual(custom?.provider, "Custom")
        XCTAssertEqual(custom?.structuredOutput, false)
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

    /// Khối có bản dịch giống chữ gốc (bỏ qua khoảng trắng, hoa/thường) không bị vẽ lại.
    func testComposeSkipsUnchangedBlocks() {
        let w = 200, h = 100
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 40, y: 40, width: 120, height: 20))
        let image = ctx.makeImage()!
        let block = TextBlock(text: "Hello  World", rect: CGRect(x: 30, y: 30, width: 140, height: 40), lineHeight: 40)

        let same = ImageComposer.compose(image, blocks: [block], translations: [" hello world "], scale: 1, fontName: "")
        XCTAssertEqual(same.dataProvider?.data as Data?, image.dataProvider?.data as Data?)
        let changed = ImageComposer.compose(image, blocks: [block], translations: ["Xin chào"], scale: 1, fontName: "")
        XCTAssertNotEqual(changed.dataProvider?.data as Data?, image.dataProvider?.data as Data?)
    }

    /// Bắt lỗi gõ sai/xoá nhầm khoá: mọi `L("khoá")` trong source phải có ở mọi file ngôn ngữ,
    /// các file có cùng tập khoá và cùng tham số định dạng (sai tham số làm `String(format:)` crash).
    func testLocalizationKeysComplete() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = root.appendingPathComponent("Shared")
        var used = Set<String>()
        let regex = try NSRegularExpression(pattern: #"\bL\("([A-Za-z0-9_.]+)""#)
        for dir in ["TScreen", "Shared", "TScreen-iOS"] {
        for case let url as URL in FileManager.default.enumerator(at: root.appendingPathComponent(dir), includingPropertiesForKeys: nil)!
        where url.pathExtension == "swift" {
            let text = try String(contentsOf: url, encoding: .utf8)
            for m in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                used.insert(String(text[Range(m.range(at: 1), in: text)!]))
            }
        }
        }
        XCTAssertFalse(used.isEmpty)
        // App thực sự nạp được JSON từ bundle (file đã được copy vào Resources).
        XCTAssertEqual(L10n.table("en")["menu.quit"], "Quit")
        let specifiers = try NSRegularExpression(pattern: "%[@d]")
        func args(_ s: String) -> [String] {
            specifiers.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { String(s[Range($0.range, in: s)!]) }
        }
        let tables = try AppLanguage.options.map { code, _ in
            (code, try JSONDecoder().decode([String: String].self, from: Data(contentsOf: source.appendingPathComponent("Resources/i18n/\(code).json"))))
        }
        let vi = tables.first { $0.0 == "vi" }!.1
        for (code, table) in tables {
            XCTAssertEqual(used.subtracting(table.keys), [], "\(code).json thiếu khoá đang dùng")
            XCTAssertEqual(Set(table.keys), Set(vi.keys), "\(code).json khác tập khoá với vi.json")
            for (key, value) in table where vi[key] != nil {
                XCTAssertEqual(args(value), args(vi[key]!), "\(code).json khoá \(key) sai tham số")
            }
        }
    }
}
