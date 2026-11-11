import CoreText
import Foundation

enum TextFitter {
    static func font(_ name: String, size: CGFloat) -> CTFont {
        name.isEmpty ? CTFontCreateUIFontForLanguage(.system, size, nil)! : CTFontCreateWithName(name as CFString, size, nil)
    }

    static func attributed(_ text: String, font: CTFont, color: CGColor? = nil) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font]
        if let color { attrs[NSAttributedString.Key(kCTForegroundColorAttributeName as String)] = color }
        return NSAttributedString(string: text, attributes: attrs)
    }

    /// Kích thước cần để vẽ `text` khi xuống dòng trong bề rộng `width`.
    static func measure(_ text: String, fontName: String, size: CGFloat, width: CGFloat) -> CGSize {
        let setter = CTFramesetterCreateWithAttributedString(attributed(text, font: font(fontName, size: size)))
        return CTFramesetterSuggestFrameSizeWithConstraints(
            setter, CFRange(), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    }

    /// Cỡ chữ lớn nhất trong [minSize, maxSize] mà chữ vẫn vừa `box` (tìm nhị phân). Không vừa thì trả minSize.
    static func fitSize(_ text: String, fontName: String, in box: CGSize, minSize: CGFloat, maxSize: CGFloat) -> CGFloat {
        func fits(_ size: CGFloat) -> Bool {
            let s = measure(text, fontName: fontName, size: size, width: box.width)
            return s.height <= box.height && s.width <= box.width
        }
        guard maxSize > minSize else { return minSize }
        if fits(maxSize) { return maxSize }
        var lo = minSize, hi = maxSize
        while hi - lo > 0.5 {
            let mid = (lo + hi) / 2
            if fits(mid) { lo = mid } else { hi = mid }
        }
        return lo
    }
}
