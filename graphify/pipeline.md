# Pipeline

**Mục đích:** điều phối toàn bộ luồng chụp → dịch → hiển thị.

**File chính:** `TScreen/App/TScreenApp.swift`, `TScreen/App/AppCoordinator.swift`

**Luồng xử lý**
1. `TScreenApp` tạo `MenuBarExtra` và đăng ký phím tắt `captureAndTranslate` (mặc định ⌃⇧T) → `AppCoordinator.shared.run()`.
2. `run()` bỏ qua nếu đang chọn vùng (`isSelecting`), rồi gọi `RegionSelector().select()` ([[chup-man-hinh]]) — trả về vùng kèm ảnh đã cắt từ màn hình đóng băng.
3. Mở viewer ngay với ảnh gốc ([[viewer]]) → OCR ([[ocr]]) → `detectLanguage` (`NLLanguageRecognizer`) → dịch ([[dich]]) → `ImageComposer.compose` ([[ve-anh]]) → cập nhật `ViewerModel`.
4. Mỗi bước gọi `lap()` ghi thời gian vào `model.timings` và `NSLog`.

**Phụ thuộc:** KeyboardShortcuts (SPM), NaturalLanguage.

**Lưu ý/bẫy**
- Mỗi lần chạy tạo `ViewerModel` và `ViewerWindowController` riêng; viewer cũ không bị đóng nên có thể lọt vào ảnh chụp mới (ảnh chụp lúc bấm phím tắt).
- `lap` là hàm cục bộ phải đánh dấu `@MainActor` vì sửa `model.timings`.
- Bước dịch + vẽ nằm trong hàm cục bộ `translateAndCompose()`. Nếu engine API (`openai`, `claude`) lỗi khi gọi API, nó gán `model.retry` → badge lỗi trong viewer có nút "Thử lại" gọi lại hàm này (dùng lại `blocks` đã OCR, đọc lại `AppSettings`).
- Lỗi ở bất kỳ bước nào → `model.status = .failed(...)`; nếu chưa có ảnh gốc thì vẫn mở viewer để báo lỗi.

## Liên quan
[[chup-man-hinh]] · [[ocr]] · [[dich]] · [[ve-anh]] · [[viewer]] · [[cai-dat]]
