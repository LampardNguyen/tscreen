# Đa ngôn ngữ giao diện

**Mục đích:** hiển thị giao diện app bằng Tiếng Việt (mặc định), English hoặc 日本語. Khác với `targetLanguage` là ngôn ngữ đích khi dịch ([[dich]]).

**File chính:** `Shared/App/L10n.swift`, `Shared/Resources/i18n/vi.json` · `en.json` · `ja.json`, test `testLocalizationKeysComplete`

**Luồng xử lý**
1. Cài đặt → Chung → "Ngôn ngữ giao diện" ghi UserDefaults `appLanguage` (`vi`/`en`/`ja`, `AppLanguage.options`).
2. Mọi chuỗi hiển thị gọi `L("nhóm.tên", args...)` (vd. `menu.capture`, `error.api`). `L10n` nạp cả ba JSON một lần (`static let`, an toàn đa luồng); tra ngôn ngữ đang chọn → thiếu thì `vi.json` → thiếu nữa thì hiện chính khoá. Tham số dùng `%@`/`%d` của `String(format:)`.
3. Các view SwiftUI đang mở (`TScreenApp`, `SettingsView`, `HistoryView`, `ViewerToolbar`) khai báo `@AppStorage(AppLanguage.key)` để vẽ lại ngay khi đổi; tiêu đề cửa sổ Cài đặt/Lịch sử gán lại mỗi lần `show()`.

**Lưu ý/bẫy**
- Thêm chuỗi UI mới: gọi `L("nhóm.tên")` và thêm khoá vào **cả ba** file JSON. Test `testLocalizationKeysComplete` fail nếu thiếu khoá, các file lệch tập khoá, hoặc lệch tham số (lệch tham số có thể làm `String(format:)` crash).
- Sửa câu chữ chỉ cần sửa JSON, không động vào code.
- Không dùng `.lproj`/String Catalog vì sẽ theo ngôn ngữ hệ thống và cần mở lại app.
- Chuỗi đã gán lúc chạy (trạng thái viewer, thông báo lỗi) giữ ngôn ngữ tại thời điểm tạo.
- Chưa dịch: phần chẩn đoán dài trong cửa sổ "Chi tiết lỗi" (`LLMTranslation.parseKeyed`), log `NSLog`, prompt gửi LLM (luôn tiếng Anh).

## Liên quan
[[cai-dat]] · [[viewer]] · [[lich-su]] · [[pipeline]]
