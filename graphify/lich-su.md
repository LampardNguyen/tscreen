# Lịch sử dịch

**Mục đích:** lưu lại các lần chụp & dịch thành công để tìm và mở lại sau.

**File chính:** `TScreen/History/HistoryStore.swift`, `TScreen/History/HistoryWindow.swift`; điểm gọi trong `AppCoordinator.run()` và `TScreenApp`.

**Luồng xử lý**
1. Trong `translateAndCompose()` ([[pipeline]]), khi `status = .done` và `HistoryStore.isEnabled` (UserDefaults `saveHistory`, mặc định true): gọi `HistoryStore.shared.add(image:size:engine:sourceText:translatedText:)`. Biến `historyID` của lần chụp giữ id: "Thử lại" thành công thì xoá bản cũ rồi thêm bản mới.
2. Lưu trên đĩa: `~/Library/Application Support/TScreen/History/<uuid>/` gồm `translated.png`, `thumb.jpg` (tối đa 240px, tạo bằng ImageIO từ file PNG) và `meta.json` (`HistoryEntry`: id, date, engine, sourceText, translatedText, width/height vùng chụp tính bằng point, `title` tuỳ chọn). Ghi lỗi giữa chừng thì xoá thư mục.
3. `add` chèn bản mới lên đầu, xoá bản cũ nhất khi vượt `limit` (200). `load()` đọc mọi `meta.json` khi khởi tạo, sắp mới nhất trước.
4. Mở danh sách: phím tắt `KeyboardShortcuts.Name.showHistory` (mặc định ⌃⇧H) hoặc menu "Lịch sử…" → `HistoryWindow.show()` (một `NSWindow` duy nhất, đổi được kích thước).
5. `HistoryView`: ô tìm kiếm (TextField tự làm, vì `.searchable` cần navigation context), `HistoryStore.filter` lọc theo tiêu đề, chữ gốc hoặc chữ dịch với `.caseInsensitive` + `.diacriticInsensitive`. Mỗi dòng gồm thumbnail, tiêu đề đậm (nếu có, khi đó chữ dịch còn 1 dòng) + 2 dòng chữ dịch, thời gian · engine, nút bút chì (alert nhập tiêu đề → `HistoryStore.rename` ghi lại `meta.json`; chuỗi trắng = bỏ tiêu đề), nút thùng rác (xoá ngay, không hỏi). Cạnh ô tìm kiếm có nút "Xoá tất cả" (`confirmationDialog` xác nhận, tắt khi danh sách rỗng).
6. Bấm một dòng → `HistoryWindow.open`: nếu `ViewerWindowController.activate(historyID:)` tìm thấy viewer đang mở có cùng `historyID` (viewer mở từ lịch sử, hoặc viewer vừa chụp được `AppCoordinator` gắn id sau khi lưu) thì chỉ đưa lên trước; không thì tạo `ViewerModel` với `original` = ảnh đã dịch, `translatedText`, `status = .done`, rồi mở viewer ([[viewer]]) ở giữa màn hình theo kích thước đã lưu.

**Phụ thuộc:** ImageIO, SwiftUI, KeyboardShortcuts, [[cai-dat]].

**Lưu ý/bẫy**
- Chỉ lưu ảnh dịch, không lưu ảnh gốc, nên viewer mở từ lịch sử không đổi được sang ảnh gốc (nút Space bị tắt vì `translated == nil`).
- Ảnh có thể chứa dữ liệu nhạy cảm: chỉ lưu trên máy; Cài đặt có công tắc tắt lưu và nút "Xoá tất cả lịch sử" (xoá cả thư mục).
- Không thêm trường vào `AppSettings` (test khởi tạo bằng memberwise init); đọc công tắc qua `HistoryStore.isEnabled`.
- `.diacriticInsensitive` không coi "đ" là "d".
- `HistoryEntry.title` phải là optional để `meta.json` cũ (không có khoá) vẫn decode được.
- Cửa sổ được dùng lại (`isReleasedWhenClosed = false`) nên phải có `collectionBehavior` `.moveToActiveSpace`, nếu không mở lại sẽ nhảy về Desktop cũ. Cửa sổ Cài đặt và Chi tiết lỗi cũng dùng lại cửa sổ nhưng chưa có cờ này.
- Dòng item dùng `.pointerStyle(.link)` (macOS 15+) để hiện con trỏ bàn tay.

## Liên quan
[[pipeline]] · [[viewer]] · [[cai-dat]]
