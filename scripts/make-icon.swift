import AppKit
let size = 1024.0
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let rect = CGRect(x: 100, y: 100, width: 824, height: 824)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: CGColor(gray: 0, alpha: 0.3))
ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 185, cornerHeight: 185, transform: nil))
ctx.setFillColor(CGColor(srgbRed: 0.2, green: 0.35, blue: 0.95, alpha: 1)); ctx.fillPath()
ctx.restoreGState()
ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 185, cornerHeight: 185, transform: nil)); ctx.clip()
let colors = [CGColor(srgbRed: 0.16, green: 0.62, blue: 1, alpha: 1), CGColor(srgbRed: 0.42, green: 0.25, blue: 0.93, alpha: 1)] as CFArray
ctx.drawLinearGradient(CGGradient(colorsSpace: nil, colors: colors, locations: [0, 1])!,
                       start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
let cfg = NSImage.SymbolConfiguration(pointSize: 520, weight: .medium)
guard let base = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil),
      let symbol = base.withSymbolConfiguration(cfg) else { fatalError("no symbol") }
let s = symbol.size, scale = 560 / max(s.width, s.height)
var r = CGRect(x: 512 - s.width * scale / 2, y: 512 - s.height * scale / 2, width: s.width * scale, height: s.height * scale)
let mask = symbol.cgImage(forProposedRect: &r, context: nil, hints: nil)!
ctx.clip(to: r, mask: mask)
ctx.setFillColor(CGColor(gray: 1, alpha: 1)); ctx.fill(r)
try! NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
