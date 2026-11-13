import AppKit

/// Overlay toàn màn hình (mỗi màn hình một cửa sổ) để kéo chọn vùng.
/// Màn hình được chụp trước rồi hiện làm nền overlay ("đóng băng"), nên popup hover không bị mất.
/// Trả về vùng theo toạ độ màn hình AppKit (gốc dưới-trái) kèm ảnh đã cắt, hoặc nil nếu huỷ.
@MainActor
final class RegionSelector {
    private var windows: [NSWindow] = []
    private var continuation: CheckedContinuation<(CGRect, CGImage)?, Never>?

    func select() async throws -> (region: CGRect, image: CGImage)? {
        var shots: [(NSScreen, CGImage)] = []
        for screen in NSScreen.screens {
            shots.append((screen, try await ScreenCapturer.capture(screen)))
        }
        return await withCheckedContinuation { (c: CheckedContinuation<(CGRect, CGImage)?, Never>) in
            continuation = c
            for (screen, shot) in shots {
                let window = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
                window.level = .screenSaver
                window.isOpaque = false
                window.backgroundColor = .clear
                window.isReleasedWhenClosed = false
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                let view = SelectionView(frame: CGRect(origin: .zero, size: screen.frame.size))
                view.frozen = NSImage(cgImage: shot, size: screen.frame.size)
                view.onFinish = { [weak self] local in
                    let result = local.flatMap { local in
                        ScreenCapturer.crop(shot, screenSize: screen.frame.size, local: local).map {
                            (local.offsetBy(dx: screen.frame.minX, dy: screen.frame.minY), $0)
                        }
                    }
                    self?.finish(result)
                }
                window.contentView = view
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(view)
                windows.append(window)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func finish(_ result: (CGRect, CGImage)?) {
        windows.forEach { $0.close() }
        windows = []
        continuation?.resume(returning: result)
        continuation = nil
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private final class SelectionView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    var frozen: NSImage?
    private var start: CGPoint?
    private var selection: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }

    /// Con trỏ chữ thập hở giữa: nét đen viền trắng để thấy rõ trên cả nền sáng lẫn tối.
    private static let crossCursor: NSCursor = {
        let size = 32.0, mid = size / 2, gap = 3.0, inset = 2.0
        let image = NSImage(size: CGSize(width: size, height: size), flipped: false) { _ in
            let path = NSBezierPath()
            path.lineCapStyle = .round
            for (dx, dy) in [(1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0)] {
                path.move(to: CGPoint(x: mid + dx * gap, y: mid + dy * gap))
                path.line(to: CGPoint(x: mid + dx * (mid - inset), y: mid + dy * (mid - inset)))
            }
            NSColor.white.setStroke(); path.lineWidth = 4; path.stroke()
            NSColor.black.setStroke(); path.lineWidth = 2; path.stroke()
            return true
        }
        return NSCursor(image: image, hotSpot: CGPoint(x: mid, y: mid))
    }()

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: Self.crossCursor)
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        selection = .zero
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start else { return }
        let p = convert(event.locationInWindow, from: nil)
        selection = CGRect(x: min(start.x, p.x), y: min(start.y, p.y), width: abs(p.x - start.x), height: abs(p.y - start.y))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        onFinish?(selection.width > 4 && selection.height > 4 ? selection : nil)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onFinish?(nil) } // ESC
    }

    override func draw(_ dirtyRect: NSRect) {
        frozen?.draw(in: bounds)
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()
        guard !selection.isEmpty else { return }
        // Vùng chọn hiện ảnh đóng băng gốc, không bị phủ tối.
        frozen?.draw(in: selection, from: selection, operation: .copy, fraction: 1)
        NSColor.white.setStroke()
        NSBezierPath(rect: selection).stroke()
        let label = "\(Int(selection.width)) × \(Int(selection.height))" as NSString
        label.draw(at: CGPoint(x: selection.minX, y: selection.maxY + 4),
                   withAttributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 11)])
    }
}
