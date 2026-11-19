# iOS

**Mục đích:** bản iOS của TScreen (chỉ trên branch `ios`, không merge vào `main`). iOS không cho app vẽ nút nổi đè app khác hay chụp màn hình app khác, nên "bấm nút nổi là dịch" làm bằng Phím tắt + AssistiveTouch.

**File chính:** `TScreen-iOS/TScreenIOSApp.swift` (TabView Hướng dẫn / Cài đặt, `SettingsForm`), `TScreen-iOS/TranslateScreenshotIntent.swift` (App Intent + `AppShortcutsProvider`), `TScreen-iOS/Signing.xcconfig`, code dùng chung ở `Shared/`.

**Luồng xử lý**
1. Phím tắt người dùng tự tạo: `Chụp ảnh màn hình` → `Dịch bằng TScreen` → `Xem nhanh`; gán vào AssistiveTouch (Chạm một lần), Chạm vào mặt sau hoặc nút Tác vụ.
2. `TranslateScreenshotIntent.perform()` (`openAppWhenRun = false`): đọc `IntentFile` thành `CGImage` → [[ocr]] → `detectLanguage` → `makeTranslator(AppSettings.current)` ([[dich]]) → `ImageComposer.compose` ([[ve-anh]], `scale = UIScreen.main.scale`) → trả `IntentFile` PNG, không lưu.
3. Lỗi ném `TranslationError` với chuỗi `L(...)` ([[da-ngon-ngu]]) để Phím tắt hiện thông báo.

**Phụ thuộc:** AppIntents, Vision, Translation, `Shared/` (OCR, Translate, Render, AppSettings, Keychain, L10n). Không dùng KeyboardShortcuts.

**Lưu ý/bẫy**
- Không có lịch sử, không chọn vùng (dịch cả màn hình); xem kỹ bằng pinch-zoom trong Xem nhanh.
- Deployment target iOS 26.0 (máy người dùng 26.7.3). Simulator thử: iPhone 17 Pro iOS 26.3 (runtime 18.5 không chạy được).
- Cài máy thật: tạo `TScreen-iOS/Signing.local.xcconfig` (gitignore) với `DEVELOPMENT_TEAM`, `CODE_SIGN_STYLE = Automatic`, `CODE_SIGN_IDENTITY = Apple Development`; bật Developer Mode; free team hết hạn sau 7 ngày.
- Chưa kiểm chứng: Apple Translation chạy trong intent nền, giới hạn thời gian intent (~30s) với engine LLM. Apple Translation cần tải gói ngôn ngữ trước.
- Cài đặt dùng chung khoá UserDefaults/Keychain với bản Mac ([[cai-dat]]).

## Liên quan
[[pipeline]] · [[ocr]] · [[dich]] · [[ve-anh]] · [[cai-dat]] · [[da-ngon-ngu]] · [[build-va-test]]
