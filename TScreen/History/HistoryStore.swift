import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Một lần chụp & dịch thành công. Ảnh nằm cạnh `meta.json` trong thư mục riêng của bản ghi.
struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let engine: String
    let sourceText: String
    let translatedText: String
    /// Kích thước vùng chụp (point) để mở lại viewer đúng cỡ ban đầu.
    let width: Double
    let height: Double
    /// Tiêu đề người dùng tự đặt để gợi nhớ; optional để `meta.json` cũ (chưa có khoá này) vẫn decode được.
    var title: String?
}

/// Lịch sử dịch lưu dạng file: `<directory>/<uuid>/{translated.png, thumb.jpg, meta.json}`.
/// Chỉ lưu ảnh đã dịch (không lưu ảnh gốc) để tốn ít dung lượng; giữ tối đa `limit` bản ghi mới nhất.
@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("TScreen/History", isDirectory: true))

    /// Khoá UserDefaults của công tắc "Lưu lịch sử"; chưa từng chỉnh = bật.
    static let enabledKey = "saveHistory"
    static var isEnabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }

    let directory: URL
    let limit: Int
    /// Mới nhất nằm đầu.
    @Published private(set) var entries: [HistoryEntry] = []

    init(directory: URL, limit: Int = 200) {
        self.directory = directory
        self.limit = limit
        load()
    }

    func folder(_ id: UUID) -> URL { directory.appendingPathComponent(id.uuidString, isDirectory: true) }
    func imageURL(_ id: UUID) -> URL { folder(id).appendingPathComponent("translated.png") }
    func thumbnailURL(_ id: UUID) -> URL { folder(id).appendingPathComponent("thumb.jpg") }

    /// Đọc mọi `meta.json`; thư mục hỏng/thiếu meta thì bỏ qua (không xoá, tránh mất dữ liệu do lỗi đọc tạm thời).
    private func load() {
        let folders = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        entries = folders.compactMap { folder in
            (try? Data(contentsOf: folder.appendingPathComponent("meta.json")))
                .flatMap { try? JSONDecoder().decode(HistoryEntry.self, from: $0) }
        }.sorted { $0.date > $1.date }
    }

    /// Lưu bản ghi mới rồi xoá các bản cũ vượt `limit`. Trả về id để có thể thay thế khi người dùng bấm "Thử lại".
    @discardableResult
    func add(image: CGImage, size: CGSize, engine: String, sourceText: String, translatedText: String) throws -> UUID {
        let entry = HistoryEntry(id: UUID(), date: Date(), engine: engine, sourceText: sourceText,
                                 translatedText: translatedText, width: size.width, height: size.height)
        let folder = folder(entry.id)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try Self.write(image, to: imageURL(entry.id), type: .png)
            // Thumbnail nhỏ để danh sách không phải giải mã ảnh Retina đầy đủ.
            if let thumb = Self.thumbnail(of: imageURL(entry.id), maxPixel: 240) { try Self.write(thumb, to: thumbnailURL(entry.id), type: .jpeg) }
            try JSONEncoder().encode(entry).write(to: folder.appendingPathComponent("meta.json"))
        } catch {
            // Ghi dở dang thì dọn thư mục để không để lại bản ghi thiếu file.
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
        entries.insert(entry, at: 0)
        while entries.count > limit { delete(entries[entries.count - 1].id) }
        return entry.id
    }

    func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: folder(id))
        entries.removeAll { $0.id == id }
    }

    /// Đổi tiêu đề rồi ghi lại `meta.json`; chuỗi rỗng/toàn khoảng trắng = bỏ tiêu đề.
    func rename(_ id: UUID, title: String) throws {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        var entry = entries[index]
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.title = trimmed.isEmpty ? nil : trimmed
        // Ghi đĩa trước, thành công mới cập nhật danh sách để UI không lệch với file.
        try JSONEncoder().encode(entry).write(to: folder(id).appendingPathComponent("meta.json"))
        entries[index] = entry
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: directory)
        entries = []
    }

    func image(_ id: UUID) -> CGImage? {
        CGImageSourceCreateWithURL(imageURL(id) as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
    }

    /// Lọc theo tiêu đề, chữ gốc hoặc chữ dịch, không phân biệt hoa thường và dấu; chuỗi rỗng = tất cả.
    static func filter(_ entries: [HistoryEntry], query: String) -> [HistoryEntry] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return entries }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return entries.filter { entry in
            [entry.title ?? "", entry.translatedText, entry.sourceText].contains { $0.range(of: query, options: options) != nil }
        }
    }

    private static func write(_ image: CGImage, to url: URL, type: UTType) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }

    private static func thumbnail(of url: URL, maxPixel: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ] as CFDictionary)
    }
}
