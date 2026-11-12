# Build và test

**Mục đích:** cách dựng project, chạy test và chạy app.

**File chính:** `project.yml`, `TScreenTests/TScreenTests.swift`, `scripts/make-icon.swift`

**Luồng xử lý**
1. `xcodegen generate` sinh `.xcodeproj` (không commit) từ `project.yml`.
2. `xcodebuild -scheme TScreen -destination 'platform=macOS' -derivedDataPath build test` — 9 unit test (joinLines, màu nền, màu chữ, co chữ, parse Claude/OpenAI, lỗi API, tích hợp OCR + vẽ).
3. Chạy lại app: `pkill -x TScreen; open build/Build/Products/Debug/TScreen.app`.

**Phụ thuộc:** XcodeGen, Xcode, SPM `KeyboardShortcuts` ghim `2.4.0`.

**Lưu ý/bẫy**
- Luôn build với `-derivedDataPath build` (rule trong `CLAUDE.md` §4); không dùng DerivedData mặc định.
- Thêm/xoá file nguồn phải chạy lại `xcodegen generate`.
- macOS 26.0 trở lên, bundle id `com.linh.tscreen`, ký ad-hoc; hardened runtime chỉ bật ở Release.
- Trong `project.yml`, khối `configs:` phải nằm sau các khoá của `base`, chen giữa sẽ lỗi parse.
- Biến môi trường `TSCREEN_TEST_OUTPUT` cho test tích hợp ghi ảnh PNG ra để xem.
- Icon app sinh bằng `scripts/make-icon.swift` (SF Symbol `text.viewfinder`).

## Liên quan
[[pipeline]] · [[cai-dat]]
