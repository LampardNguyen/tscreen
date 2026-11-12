# Viewer

**Mục đích:** hiện ảnh gốc/ảnh dịch trong cửa sổ không viền kèm thanh công cụ nổi.

**File chính:** `TScreen/Viewer/ViewerWindow.swift`

**Luồng xử lý**
1. `ViewerModel` (ObservableObject) giữ ảnh gốc, ảnh dịch, chữ dịch, trạng thái, zoom, ghim, timings.
2. `ViewerWindowController.show` tạo `ViewerWindow` (borderless, trong suốt) tại vùng vừa chụp và một `NSPanel` không kích hoạt làm thanh công cụ, gắn làm cửa sổ con.
3. `layout()` đổi kích thước theo zoom (giữ góc trên-trái) và đặt thanh công cụ dưới ảnh, tránh tràn màn hình.
4. Mỗi lần chụp là một controller mới; danh sách `static open` giữ các viewer đang mở. `close()` đóng một cái, `closeAll()` đóng hết (⌥-bấm nút đóng).
5. Kéo ở một trong bốn góc (vùng 16pt) để đổi kích thước: `DraggableHostingView.mouseDown` gọi `resizeFromCorner()`, hàm này tự chạy vòng lặp sự kiện chuột, luôn giữ tỉ lệ (thực chất là đổi `model.zoom`, giới hạn 0.25–4), góc đối diện đứng yên. Không kéo được theo một chiều ngang hoặc dọc. `CornerMarks` vẽ bốn dấu góc chữ L đè lên ảnh để gợi ý (chỉ hiển thị, không có trong ảnh chép/lưu).
6. Phím: ESC/⌘W đóng, Space đổi gốc/dịch, ⌘C chép ảnh, ⇧⌘C chép chữ, ⌘S lưu PNG, ⌘+/⌘− zoom.

**Phụ thuộc:** SwiftUI, AppKit, Combine.

**Lưu ý/bẫy**
- SwiftUI nuốt sự kiện chuột nên phải dùng `DraggableHostingView` (`performDrag`) mới kéo được cửa sổ.
- `ViewerWindow.controller` là `weak`; controller sống nhờ danh sách `open`.
- Cửa sổ borderless phải override `canBecomeKey` mới nhận phím.

## Liên quan
[[pipeline]] · [[ve-anh]]
