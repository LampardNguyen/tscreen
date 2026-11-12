# Vẽ ảnh

**Mục đích:** xoá chữ gốc và vẽ chữ dịch vào đúng vị trí trên ảnh.

**File chính:** `TScreen/Render/ImageComposer.swift`, `TScreen/Render/ColorSampler.swift`, `TScreen/Render/TextFitter.swift`

**Luồng xử lý** (`ImageComposer.compose`, cho từng khối)
1. `Bitmap.backgroundColor(in:)` — trung vị các pixel trên viền khung.
2. `Bitmap.textColor(in:background:)` — trung bình các pixel cách màu nền hơn 0.6·khoảng cách lớn nhất; nếu khoảng cách lớn nhất ≤ 60 thì dùng đen/trắng.
3. Tô hình chữ nhật bo góc (có nới lề) bằng màu nền.
4. `TextFitter.fitSize` tìm nhị phân cỡ chữ lớn nhất vừa khung, trong khoảng 8·scale đến lineHeight·0.85; vẫn tràn thì nới khung xuống dưới.
5. Vẽ bằng `CTFramesetter` / `CTFrameDraw`.

**Phụ thuộc:** Core Graphics, Core Text; font lấy từ [[cai-dat]].

**Lưu ý/bẫy**
- Mọi toạ độ là pixel gốc trên-trái (theo [[ocr]]); `scale` = pixel/point.
- Nền gradient hoặc ảnh chụp sẽ lộ mảng màu phẳng.

## Liên quan
[[pipeline]] · [[ocr]] · [[viewer]]
