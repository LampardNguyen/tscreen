# Cài đặt

**Mục đích:** lưu và chỉnh các tuỳ chọn của app.

**File chính:** `TScreen/Settings/SettingsView.swift`, `TScreen/Settings/Keychain.swift`, `AppCoordinator.showSettings()`

**Luồng xử lý**
1. Menu "Cài đặt…" → `AppCoordinator.showSettings()` tự tạo `NSWindow` 460×420 chứa `SettingsView`.
2. `SettingsView` dùng `@AppStorage`: `targetLanguage` (mặc định `vi`), `engine` (`apple`), `claudeModel`, `openAIModel`, `openAIReasoningEffort` (`minimal`), `fontName`; có ô ghi phím tắt và dòng trạng thái quyền Screen Recording.
3. `AppSettings.current` đọc các giá trị này cho [[pipeline]].
4. API key lưu ở Keychain (generic password, service `com.linh.tscreen`, khoá `claudeAPIKey`, `openAIAPIKey`).

**Phụ thuộc:** KeyboardShortcuts, Security.

**Lưu ý/bẫy**
- App là `LSUIElement` nên scene `Settings`/`SettingsLink` không mở được — phải tự tạo cửa sổ.
- Cửa sổ phải có kích thước cố định, nếu không chỉ hiện thanh tiêu đề.
- Khi engine khác `apple` hiện cảnh báo chữ sẽ được gửi ra ngoài máy ([[dich]]).
- Không bao giờ log hay commit API key; `.env` đã nằm trong `.gitignore`.

## Liên quan
[[pipeline]] · [[dich]] · [[chup-man-hinh]]
