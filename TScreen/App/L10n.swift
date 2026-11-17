import Foundation

/// Ngôn ngữ giao diện của app (khác ngôn ngữ đích khi dịch). Lưu ở UserDefaults, mặc định tiếng Việt.
/// Tự quản lý thay vì dùng `.lproj` để đổi ngay trong Cài đặt, không phụ thuộc ngôn ngữ hệ thống và không cần mở lại app.
enum AppLanguage {
    static let key = "appLanguage"
    static let fallback = "vi"
    static let options = [("vi", "Tiếng Việt"), ("en", "English"), ("ja", "日本語")]
    static var current: String { UserDefaults.standard.string(forKey: key) ?? fallback }
}

/// Lấy chuỗi giao diện theo khoá (vd. `menu.capture`) từ `Resources/i18n/<mã>.json`.
/// Thiếu khoá ở ngôn ngữ đang chọn thì dùng tiếng Việt, thiếu cả tiếng Việt thì hiện chính khoá để dễ phát hiện.
/// Chuỗi có tham số dùng `%@`/`%d` của `String(format:)` để mỗi ngôn ngữ đặt tham số ở vị trí riêng.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = L10n.table(AppLanguage.current)[key] ?? L10n.table(AppLanguage.fallback)[key] ?? key
    return args.isEmpty ? format : String(format: format, arguments: args)
}

enum L10n {
    /// Đọc mọi file ngôn ngữ một lần khi dùng lần đầu; `static let` khởi tạo an toàn đa luồng
    /// vì `L` còn được gọi từ các translator chạy nền.
    private static let tables: [String: [String: String]] = Dictionary(uniqueKeysWithValues: AppLanguage.options.map { code, _ in
        (code, Bundle.main.url(forResource: code, withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:])
    })

    static func table(_ language: String) -> [String: String] { tables[language] ?? [:] }
}
