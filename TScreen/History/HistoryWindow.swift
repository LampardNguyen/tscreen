import SwiftUI

/// Cửa sổ danh sách lịch sử dịch; chỉ giữ một cửa sổ, mở lại thì đưa lên trước.
@MainActor
enum HistoryWindow {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 560, height: 640),
                             styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
            w.title = "Lịch sử dịch"
            w.isReleasedWhenClosed = false
            // Cửa sổ được dùng lại sau khi đóng: thiếu cờ này macOS chuyển về Desktop (Space) nơi cửa sổ mở lần đầu.
            w.collectionBehavior.insert(.moveToActiveSpace)
            w.contentView = NSHostingView(rootView: HistoryView(store: .shared))
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Mở lại bản dịch trong viewer như lúc vừa dịch xong (chỉ có ảnh dịch nên không đổi sang ảnh gốc được).
    static func open(_ entry: HistoryEntry, store: HistoryStore) {
        if ViewerWindowController.activate(historyID: entry.id) { return }
        guard let image = store.image(entry.id) else { return }
        let model = ViewerModel()
        model.original = image
        model.translatedText = entry.translatedText
        model.status = .done
        let size = CGSize(width: entry.width, height: entry.height)
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let viewer = ViewerWindowController()
        viewer.historyID = entry.id
        viewer.show(model, near: CGRect(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2,
                                                          width: size.width, height: size.height))
    }
}

private struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    @State private var query = ""
    @State private var confirmDeleteAll = false
    /// Bản ghi đang sửa tiêu đề (nil = không hiện alert) và nội dung ô nhập.
    @State private var renaming: HistoryEntry?
    @State private var titleDraft = ""

    private var results: [HistoryEntry] { HistoryStore.filter(store.entries, query: query) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Tìm trong tiêu đề, chữ gốc hoặc chữ dịch", text: $query).textFieldStyle(.plain)
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain).foregroundStyle(.secondary)
                }
                // Xoá từng item thì xoá ngay, còn xoá tất cả không hoàn tác được nên phải xác nhận.
                Button("Xoá tất cả", role: .destructive) { confirmDeleteAll = true }
                    .disabled(store.entries.isEmpty)
                    .confirmationDialog("Xoá toàn bộ \(store.entries.count) bản dịch trong lịch sử?", isPresented: $confirmDeleteAll) {
                        Button("Xoá tất cả", role: .destructive) { store.deleteAll() }
                    }
            }
            .padding(10)
            Divider()
            if results.isEmpty {
                Text(store.entries.isEmpty ? "Chưa có bản dịch nào." : "Không tìm thấy kết quả.")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(results) { entry in
                    HistoryRow(entry: entry, thumbnail: store.thumbnailURL(entry.id),
                               onRename: { titleDraft = entry.title ?? ""; renaming = entry },
                               onDelete: { store.delete(entry.id) })
                        .contentShape(Rectangle())
                        .pointerStyle(.link)
                        .onTapGesture { HistoryWindow.open(entry, store: store) }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 320)
        // Alert sửa tiêu đề; để trống rồi Lưu = bỏ tiêu đề.
        .alert("Đặt tiêu đề", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Tiêu đề gợi nhớ", text: $titleDraft)
            Button("Lưu") { if let entry = renaming { try? store.rename(entry.id, title: titleDraft) } }
            Button("Huỷ", role: .cancel) {}
        }
    }
}

private struct HistoryRow: View {
    let entry: HistoryEntry
    let thumbnail: URL
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = NSImage(contentsOf: thumbnail) {
                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 64)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 4) {
                // Có tiêu đề thì hiện đậm ở trên, chữ dịch rút còn 1 dòng để chiều cao dòng không đổi.
                if let title = entry.title {
                    Text(title).fontWeight(.semibold).lineLimit(1)
                }
                Text(entry.translatedText).lineLimit(entry.title == nil ? 2 : 1)
                Text("\(entry.date.formatted(date: .abbreviated, time: .shortened)) · \(entry.engine)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRename) { Image(systemName: "pencil") }
                .buttonStyle(.plain).foregroundStyle(.secondary).help("Đặt tiêu đề")
            Button(action: onDelete) { Image(systemName: "trash") }
                .buttonStyle(.plain).foregroundStyle(.red).help("Xoá")
        }
        .padding(.vertical, 4)
    }
}
