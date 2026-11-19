import CoreGraphics

struct RGB: Equatable {
    var r, g, b: Double // 0...255
    func distance(_ o: RGB) -> Double {
        ((r - o.r) * (r - o.r) + (g - o.g) * (g - o.g) + (b - o.b) * (b - o.b)).squareRoot()
    }
    var luminance: Double { 0.299 * r + 0.587 * g + 0.114 * b }
    var cgColor: CGColor { CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: 1) }
}

/// Ảnh RGBA8, gốc trên-trái.
struct Bitmap {
    let width: Int, height: Int
    var data: [UInt8]

    init(width: Int, height: Int, data: [UInt8]) {
        self.width = width; self.height = height; self.data = data
    }

    init?(_ image: CGImage) {
        width = image.width; height = image.height
        data = [UInt8](repeating: 0, count: width * height * 4)
        let ok = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                                      bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        if !ok { return nil }
    }

    func pixel(_ x: Int, _ y: Int) -> RGB {
        let i = (y * width + x) * 4
        return RGB(r: Double(data[i]), g: Double(data[i + 1]), b: Double(data[i + 2]))
    }

    private func clamp(_ rect: CGRect) -> (x0: Int, y0: Int, x1: Int, y1: Int)? {
        let r = rect.integral.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        guard !r.isEmpty else { return nil }
        return (Int(r.minX), Int(r.minY), Int(r.maxX) - 1, Int(r.maxY) - 1)
    }

    /// Màu nền: trung vị từng kênh của các điểm ảnh trên viền khung.
    func backgroundColor(in rect: CGRect) -> RGB {
        guard let b = clamp(rect) else { return RGB(r: 255, g: 255, b: 255) }
        var px: [RGB] = []
        for x in b.x0...b.x1 { px.append(pixel(x, b.y0)); px.append(pixel(x, b.y1)) }
        for y in b.y0...b.y1 { px.append(pixel(b.x0, y)); px.append(pixel(b.x1, y)) }
        func median(_ v: [Double]) -> Double { v.sorted()[v.count / 2] }
        return RGB(r: median(px.map(\.r)), g: median(px.map(\.g)), b: median(px.map(\.b)))
    }

    /// Màu chữ: trung bình các điểm ảnh khác màu nền nhiều nhất; nếu tương phản thấp thì đen/trắng.
    func textColor(in rect: CGRect, background: RGB) -> RGB {
        let fallback = background.luminance > 128 ? RGB(r: 0, g: 0, b: 0) : RGB(r: 255, g: 255, b: 255)
        guard let b = clamp(rect) else { return fallback }
        var px: [(RGB, Double)] = []
        for y in b.y0...b.y1 { for x in b.x0...b.x1 { let p = pixel(x, y); px.append((p, p.distance(background))) } }
        let maxDistance = px.map(\.1).max() ?? 0
        guard maxDistance > 60 else { return fallback }
        let far = px.filter { $0.1 > maxDistance * 0.6 }.map(\.0)
        let n = Double(far.count)
        return RGB(r: far.map(\.r).reduce(0, +) / n, g: far.map(\.g).reduce(0, +) / n, b: far.map(\.b).reduce(0, +) / n)
    }
}
