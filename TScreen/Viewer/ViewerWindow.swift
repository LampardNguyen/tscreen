import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class ViewerModel: ObservableObject {
    enum Status: Equatable { case working(String), done, failed(String) }
    @Published var original: CGImage?
    @Published var translated: CGImage?
    @Published var translatedText = ""
    @Published var status: Status = .working("Đang chụp…")
    @Published var showOriginal = false
    @Published var zoom: CGFloat = 1
    @Published var pinned = true
    @Published var timings: [String] = []
    @Published var showTimings = false

    var displayed: CGImage? { showOriginal ? original : (translated ?? original) }
}

/// Cửa sổ ảnh không viền, trong suốt + thanh công cụ nổi riêng bên dưới.
@MainActor
final class ViewerWindowController {
    /// Các viewer đang mở; mỗi lần chụp tạo một viewer mới.
    private static var open: [ViewerWindowController] = []
    static func closeAll() { open.forEach { $0.close() } }

    private var window: ViewerWindow?
    private var toolbar: NSPanel?
    private var model: ViewerModel?
    private var baseSize = CGSize.zero
    private var cancellables: Set<AnyCancellable> = []

    func show(_ model: ViewerModel, near region: CGRect) {
        close()
        Self.open.append(self)
        self.model = model
        baseSize = model.original == nil ? CGSize(width: 420, height: 90) : region.size

        let window = ViewerWindow(contentRect: CGRect(origin: CGPoint(x: region.minX, y: region.maxY - baseSize.height), size: baseSize),
                                  styleMask: .borderless, backing: .buffered, defer: false)
        window.controller = self
        configure(window)
        window.isMovableByWindowBackground = true
        window.contentView = DraggableHostingView(rootView: ViewerImageView(model: model))

        let host = NSHostingView(rootView: ViewerToolbar(model: model, controller: self))
        let toolbar = NSPanel(contentRect: CGRect(origin: .zero, size: host.fittingSize),
                              styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configure(toolbar)
        toolbar.contentView = host

        self.window = window
        self.toolbar = toolbar
        layout()
        window.addChildWindow(toolbar, ordered: .above)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        model.$zoom.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in self?.layout() }.store(in: &cancellables)
        model.$pinned.dropFirst().sink { [weak self] pinned in
            self?.window?.level = pinned ? .floating : .normal
            self?.toolbar?.level = pinned ? .floating : .normal
        }.store(in: &cancellables)
    }

    func close() {
        Self.open.removeAll { $0 === self }
        cancellables = []
        toolbar?.close()
        window?.close()
        toolbar = nil
        window = nil
        model = nil
    }

    private func configure(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.isReleasedWhenClosed = false
    }

    /// Đổi kích thước ảnh theo zoom (giữ góc trên-trái) và đặt thanh công cụ ngay dưới ảnh.
    private func layout() {
        guard let window, let toolbar, let model else { return }
        let size = CGSize(width: baseSize.width * model.zoom, height: baseSize.height * model.zoom)
        let top = window.frame.maxY
        window.setFrame(CGRect(x: window.frame.minX, y: top - size.height, width: size.width, height: size.height), display: true)

        let bar = toolbar.frame.size
        var origin = CGPoint(x: window.frame.midX - bar.width / 2, y: window.frame.minY - bar.height - 8)
        if let visible = (window.screen ?? NSScreen.main)?.visibleFrame {
            if origin.y < visible.minY { origin.y = window.frame.minY + 8 } // hết chỗ bên dưới thì nằm đè lên mép dưới ảnh
            origin.x = min(max(origin.x, visible.minX), visible.maxX - bar.width)
        }
        toolbar.setFrameOrigin(origin)
    }

    // MARK: Hành động

    func toggleOriginal() {
        guard let model, model.translated != nil else { return }
        model.showOriginal.toggle()
    }

    func zoom(by delta: CGFloat) {
        guard let model else { return }
        model.zoom = min(4, max(0.25, model.zoom + delta))
    }

    func copyImage() {
        guard let image = model?.displayed else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([NSImage(cgImage: image, size: .zero)])
    }

    func copyText() {
        guard let text = model?.translatedText, !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func save() {
        guard let image = model?.displayed else { return }
        let panel = NSSavePanel()
        panel.level = .modalPanel
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "tscreen.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
    }
}

/// Cửa sổ không viền vẫn nhận phím: ESC đóng, Space đổi gốc/dịch, ⌘C ⇧⌘C ⌘S ⌘+ ⌘−.
final class ViewerWindow: NSWindow {
    weak var controller: ViewerWindowController?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: controller?.close()
        case 49: controller?.toggleOriginal()
        default: super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command), let controller else { return super.performKeyEquivalent(with: event) }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "c": flags.contains(.shift) ? controller.copyText() : controller.copyImage()
        case "s": controller.save()
        case "=", "+": controller.zoom(by: 0.25)
        case "-": controller.zoom(by: -0.25)
        case "w": controller.close()
        default: return super.performKeyEquivalent(with: event)
        }
        return true
    }
}

/// SwiftUI nuốt sự kiện chuột nên isMovableByWindowBackground không có tác dụng; tự kéo cửa sổ.
private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

struct ViewerImageView: View {
    @ObservedObject var model: ViewerModel

    var body: some View {
        ZStack(alignment: .bottom) {
            if let image = model.displayed {
                Image(decorative: image, scale: 1).resizable()
            } else {
                Rectangle().fill(.regularMaterial)
            }
            statusBadge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var statusBadge: some View {
        switch model.status {
        case .working(let message):
            HStack(spacing: 6) { ProgressView().controlSize(.small); Text(message) }.modifier(Badge())
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill").textSelection(.enabled).modifier(Badge())
        case .done:
            if model.showTimings {
                Text(model.timings.joined(separator: " · ")).monospacedDigit().modifier(Badge())
            }
        }
    }

    private struct Badge: ViewModifier {
        func body(content: Content) -> some View {
            content.font(.callout).padding(.horizontal, 10).padding(.vertical, 6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(8)
        }
    }
}

struct ViewerToolbar: View {
    @ObservedObject var model: ViewerModel
    let controller: ViewerWindowController

    var body: some View {
        HStack(spacing: 14) {
            button(model.showOriginal ? "Xem bản dịch (Space)" : "Xem ảnh gốc (Space)",
                   model.showOriginal ? "character.bubble" : "photo") { controller.toggleOriginal() }
                .disabled(model.translated == nil)
            button("Thu nhỏ (⌘−)", "minus.magnifyingglass") { controller.zoom(by: -0.25) }
            button("Phóng to (⌘+)", "plus.magnifyingglass") { controller.zoom(by: 0.25) }
            Divider().frame(height: 18)
            button("Sao chép ảnh (⌘C)", "doc.on.doc") { controller.copyImage() }
            button("Sao chép chữ dịch (⇧⌘C)", "text.quote") { controller.copyText() }
                .disabled(model.translatedText.isEmpty)
            button("Lưu PNG (⌘S)", "square.and.arrow.down") { controller.save() }
            button(model.pinned ? "Bỏ ghim" : "Ghim trên cùng", model.pinned ? "pin.fill" : "pin") { model.pinned.toggle() }
            button("Thời gian xử lý từng bước", "stopwatch") { model.showTimings.toggle() }
            Divider().frame(height: 18)
            button("Đóng (Esc) · ⌥-bấm: đóng tất cả", "xmark") {
                NSEvent.modifierFlags.contains(.option) ? ViewerWindowController.closeAll() : controller.close()
            }.foregroundStyle(.red)
        }
        .font(.system(size: 17))
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(Color(nsColor: .windowBackgroundColor), in: Capsule())
        .fixedSize()
    }

    private func button(_ help: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).frame(width: 22, height: 22) }
            .buttonStyle(.plain)
            .help(help)
    }
}
