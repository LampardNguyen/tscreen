# Chụp màn hình

**Mục đích:** cho người dùng kéo chọn một vùng rồi chụp vùng đó ở độ phân giải Retina.

**File chính:** `TScreen/Capture/RegionSelector.swift`, `TScreen/Capture/ScreenCapturer.swift`

**Luồng xử lý**
1. `RegionSelector.select()` trước tiên gọi `ScreenCapturer.capture(screen)` chụp nguyên từng màn hình ("đóng băng"), sau đó mới mở mỗi màn hình một cửa sổ không viền mức `.screenSaver`; `SelectionView` xử lý kéo chuột, ESC để huỷ; trả về rect theo toạ độ AppKit (gốc dưới-trái) hoặc `nil`.
2. Con trỏ chữ thập tự vẽ (32px, nét đen viền trắng, hở ở tâm) gắn qua `resetCursorRects`.
3. `SelectionView` vẽ ảnh đóng băng làm nền (phủ tối 30%, vùng chọn hiện ảnh gốc).
4. Khi thả chuột, `ScreenCapturer.crop` cắt vùng chọn từ ảnh đóng băng (đổi sang pixel, gốc trên-trái); `select()` trả về `(region, image)`, không chụp lại.
5. `ScreenCapturer.capture` kiểm tra quyền Screen Recording, đổi frame màn hình sang toạ độ gốc trên-trái, gọi `SCScreenshotManager.captureImage(in:)`. Lỗi quyền được `select()` ném ra, [[pipeline]] mở viewer báo lỗi giữa màn hình.

**Phụ thuộc:** ScreenCaptureKit, quyền Screen Recording (`CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess`).

**Lưu ý/bẫy**
- Phải chụp TRƯỚC khi mở overlay: overlay lấy focus/chuột làm browser nhận `mouseleave`/`blur` và đóng popup hover.
- Nội dung động (video) đứng yên trong lúc chọn vùng.
- Build lại với chữ ký ad-hoc có thể làm macOS hỏi lại quyền Screen Recording.
- Tỉ lệ pixel/point được tính ở [[pipeline]] bằng `image.width / region.width`.

## Liên quan
[[pipeline]] · [[ocr]] · [[cai-dat]]
