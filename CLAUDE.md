# CLAUDE.md

## 1. Bắt đầu mỗi lần làm

1. Đọc `graphify/index.md` trước khi phân tích một chức năng (xem §3), chỉ đọc code khi bản đồ chưa đủ.
2. Trao đổi với người dùng bằng tiếng Việt.

## 2. Changelog

**Mỗi task đều ghi vào `CHANGELOG.md`** (gốc repo, tạo nếu chưa có): thêm mục mới lên đầu file
dạng `## YYYY-MM-DD — <tên task>` + gạch đầu dòng thay đổi chính, commit cùng thay đổi.

## 3. Bản đồ tri thức `graphify/`

- **Trước khi phân tích** một chức năng: đọc `graphify/index.md` rồi note liên quan.
- **Sau khi phân tích xong** một chức năng chưa có note: ghi thành note mới trong `graphify/`.
  Kiểu Obsidian: mỗi note 1 chủ đề, liên kết chéo bằng `[[tên-note]]`, có mục *Liên quan*;
  `graphify/index.md` là chỉ mục gốc (MOC) trỏ tới mọi note.
  Nội dung note: mục đích, file chính (đường dẫn), luồng xử lý, phụ thuộc, lưu ý/bẫy.
- **Khi sửa logic** làm note không còn đúng: cập nhật note (và `index.md` nếu thêm/xoá note) trong cùng commit.
