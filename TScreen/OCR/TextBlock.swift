import CoreGraphics

/// Một đoạn chữ đã OCR. Toạ độ theo pixel của ảnh, gốc trên-trái.
struct TextBlock {
    var text: String
    var rect: CGRect
    var lineHeight: CGFloat

    /// Nối các dòng thành đoạn: chữ CJK không chèn dấu cách, còn lại thì có.
    static func joinLines(_ lines: [String]) -> String {
        var result = ""
        for line in lines {
            if let last = result.unicodeScalars.last, let first = line.unicodeScalars.first,
               !(isCJK(last) && isCJK(first)) {
                result += " "
            }
            result += line
        }
        return result
    }

    private static func isCJK(_ s: Unicode.Scalar) -> Bool {
        (0x3000...0x30FF).contains(s.value) || (0x3400...0x9FFF).contains(s.value) || (0xFF00...0xFFEF).contains(s.value)
    }
}
