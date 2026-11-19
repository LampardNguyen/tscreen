# Build và test

**Mục đích:** cách dựng project, chạy test và chạy app.

**File chính:** `project.yml`, `TScreenTests/TScreenTests.swift`, `scripts/make-icon.swift`

**Luồng xử lý**
1. `xcodegen generate` sinh `.xcodeproj` (không commit) từ `project.yml`.
2. `xcodebuild -scheme TScreen -destination 'platform=macOS' -derivedDataPath build test` — 18 unit test (khối không đổi không vẽ lại, lịch sử lưu/đọc/tìm/xoá/giới hạn, joinLines, màu nền, màu chữ, co chữ, parse Claude/OpenAI, input/schema có id, thiếu id giữ chữ gốc, phân loại lỗi parse, cấu hình engine Custom, lỗi API, tích hợp OCR + vẽ).
3. iOS: `xcodebuild -scheme TScreen-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3' -derivedDataPath build build` → `build/Build/Products/Debug-iphonesimulator/TScreen.app` (xem [[ios]]).
4. Chạy lại app: `pkill -x TScreen; open build/Build/Products/Debug/TScreen.app`.

**Phụ thuộc:** XcodeGen, Xcode, SPM `KeyboardShortcuts` ghim `2.4.0`.

**Lưu ý/bẫy**
- Luôn build với `-derivedDataPath build` (rule trong `CLAUDE.md` §4); không dùng DerivedData mặc định.
- Thêm/xoá file nguồn phải chạy lại `xcodegen generate`.
- macOS 26.0 trở lên, bundle id `com.linh.tscreen`, ký ad-hoc; hardened runtime chỉ bật ở Release.
- Trong `project.yml`, khối `configs:` phải nằm sau các khoá của `base`, chen giữa sẽ lỗi parse.
- Biến môi trường `TSCREEN_TEST_OUTPUT` cho test tích hợp ghi ảnh PNG ra để xem.
- Code dùng chung nằm ở `Shared/` (target macOS: `[TScreen, Shared]`, iOS: `[TScreen-iOS, Shared]`). Test i18n quét `L("…")` ở cả `TScreen`, `Shared`, `TScreen-iOS`.
- Icon app sinh bằng `scripts/make-icon.swift` (SF Symbol `text.viewfinder`).

## Liên quan
[[pipeline]] · [[cai-dat]] · [[ios]]
