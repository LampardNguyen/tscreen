import Vision

enum TextRecognizer {
    static func recognize(_ image: CGImage) async throws -> [TextBlock] {
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.recognitionLanguages = [.init(identifier: "ja-JP"), .init(identifier: "en-US")]
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        let size = CGSize(width: image.width, height: image.height)

        var blocks: [TextBlock] = []
        for observation in try await request.perform(on: image) {
            let document = observation.document
            // Ưu tiên đoạn văn; nếu Vision không chia đoạn thì mỗi dòng là một khối.
            let groups = document.paragraphs.isEmpty ? document.text.lines.map { [$0] } : document.paragraphs.map(\.lines)
            for lines in groups where !lines.isEmpty {
                let rects = lines.map { $0.boundingBox.toImageCoordinates(size, origin: .upperLeft) }
                blocks.append(TextBlock(
                    text: TextBlock.joinLines(lines.map(\.transcript)),
                    rect: rects.dropFirst().reduce(rects[0]) { $0.union($1) },
                    lineHeight: rects.map(\.height).reduce(0, +) / CGFloat(rects.count)))
            }
        }
        return blocks
    }
}
