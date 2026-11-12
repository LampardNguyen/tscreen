# Pipeline

**Mục đích:** điều phối toàn bộ luồng chụp → dịch → hiển thị.

**File chính:** `TScreen/App/TScreenApp.swift`, `TScreen/App/AppCoordinator.swift`

**Luồng xử lý**
1. `TScreenApp` tạo `MenuBarExtra` và đăng ký phím tắt `captureAndTranslate` (mặc định ⌃⇧T) → `AppCoordinator.shared.run()`.
2. `run()` bỏ qua nếu đang chọn vùng (`isSelecting`), rồi gọi `RegionSelector().select()` ([[chup-man-hinh]]).
3. Chụp ảnh → mở viewer ngay với ảnh gốc ([[viewer]]) → OCR ([[ocr]]) → `detectLanguage` (`NLLanguageRecognizer`) → dịch ([[dich]]) → `ImageComposer.compose` ([[ve-anh]]) → cập nhật `ViewerModel`.
4. Mỗi bước gọi `lap()` ghi thời gian vào `model.timings` và `NSLog`.

**Phụ thuộc:** KeyboardShortcuts (SPM), NaturalLanguage.

**Lưu ý/bẫy**
- Mỗi lần chạy tạo `ViewerModel` và `ViewerWindowController` riêng; viewer cũ không bị đóng nên có thể lọt vào ảnh chụp mới.
- `lap` là hàm cục bộ phải đánh dấu `@MainActor` vì sửa `model.timings`.
- Lỗi ở bất kỳ bước nào → `model.status = .failed(...)`; nếu chưa có ảnh gốc thì vẫn mở viewer để báo lỗi.

## Liên quan
[[chup-man-hinh]] · [[ocr]] · [[dich]] · [[ve-anh]] · [[viewer]] · [[cai-dat]]
