# Chụp màn hình

**Mục đích:** cho người dùng kéo chọn một vùng rồi chụp vùng đó ở độ phân giải Retina.

**File chính:** `TScreen/Capture/RegionSelector.swift`, `TScreen/Capture/ScreenCapturer.swift`

**Luồng xử lý**
1. `RegionSelector.select()` mở mỗi màn hình một cửa sổ không viền mức `.screenSaver`; `SelectionView` xử lý kéo chuột, ESC để huỷ; trả về rect theo toạ độ AppKit (gốc dưới-trái) hoặc `nil`.
2. Con trỏ chữ thập tự vẽ (32px, nét đen viền trắng, hở ở tâm) gắn qua `resetCursorRects`.
3. Chờ 80ms cho overlay biến mất rồi mới chụp.
4. `ScreenCapturer.capture` kiểm tra quyền Screen Recording, đổi rect sang toạ độ gốc trên-trái, gọi `SCScreenshotManager.captureImage(in:)`.

**Phụ thuộc:** ScreenCaptureKit, quyền Screen Recording (`CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess`).

**Lưu ý/bẫy**
- Build lại với chữ ký ad-hoc có thể làm macOS hỏi lại quyền Screen Recording.
- Tỉ lệ pixel/point được tính ở [[pipeline]] bằng `image.width / region.width`.

## Liên quan
[[pipeline]] · [[ocr]] · [[cai-dat]]
