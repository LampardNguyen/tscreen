import CoreGraphics
import CoreText
import Foundation

enum ImageComposer {
    /// Xoá chữ gốc (tô màu nền) và vẽ chữ dịch vào từng khối. `scale` = pixel / point.
    static func compose(_ image: CGImage, blocks: [TextBlock], translations: [String], scale: CGFloat, fontName: String) -> CGImage {
        let w = image.width, h = image.height
        guard let bitmap = Bitmap(image),
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        let pad = 2 * scale
        for (block, text) in zip(blocks, translations) {
            let background = bitmap.backgroundColor(in: block.rect.insetBy(dx: -pad, dy: -pad))
            let color = bitmap.textColor(in: block.rect, background: background)

            var box = block.rect
            let minSize = 8 * scale
            let size = TextFitter.fitSize(text, fontName: fontName, in: box.size, minSize: minSize,
                                          maxSize: max(minSize, block.lineHeight * 0.85))
            // Vẫn tràn ở cỡ nhỏ nhất thì nới khung xuống dưới.
            let needed = TextFitter.measure(text, fontName: fontName, size: size, width: box.width)
            box.size.height = min(max(box.height, ceil(needed.height)), CGFloat(h) - box.minY)

            // CGContext gốc dưới-trái, khối chữ gốc trên-trái.
            let flipped = CGRect(x: box.minX, y: CGFloat(h) - box.maxY, width: box.width, height: box.height)
            ctx.setFillColor(background.cgColor)
            ctx.addPath(CGPath(roundedRect: flipped.insetBy(dx: -pad, dy: -pad), cornerWidth: pad, cornerHeight: pad, transform: nil))
            ctx.fillPath()

            let string = TextFitter.attributed(text, font: TextFitter.font(fontName, size: size), color: color.cgColor)
            let setter = CTFramesetterCreateWithAttributedString(string)
            CTFrameDraw(CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: flipped, transform: nil), nil), ctx)
        }
        return ctx.makeImage() ?? image
    }
}
