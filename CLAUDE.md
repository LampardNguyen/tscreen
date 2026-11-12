# CLAUDE.md

## 1. Bắt đầu mỗi lần làm

1. Đọc `graphify/index.md` trước khi phân tích một chức năng (xem §3), chỉ đọc code khi bản đồ chưa đủ.
2. Trao đổi với người dùng bằng tiếng Việt.

## 2. Changelog

**Mỗi task đều ghi vào `CHANGELOG.md`** (gốc repo, tạo nếu chưa có), commit cùng thay đổi:

- Mỗi ngày chỉ có một mục `## YYYY-MM-DD`, mục mới nhất nằm trên đầu file.
- Trước khi ghi, kiểm tra đã có mục của ngày hôm nay chưa: có rồi thì chỉ thêm gạch đầu dòng mới
  vào mục đó, không tạo thêm tiêu đề cùng ngày; chưa có thì mới tạo mục mới.

## 3. Bản đồ tri thức `graphify/`

- **Trước khi phân tích** một chức năng: đọc `graphify/index.md` rồi note liên quan.
- **Sau khi phân tích xong** một chức năng chưa có note: ghi thành note mới trong `graphify/`.
  Kiểu Obsidian: mỗi note 1 chủ đề, liên kết chéo bằng `[[tên-note]]`, có mục *Liên quan*;
  `graphify/index.md` là chỉ mục gốc (MOC) trỏ tới mọi note.
  Nội dung note: mục đích, file chính (đường dẫn), luồng xử lý, phụ thuộc, lưu ý/bẫy.
- **Khi sửa logic** làm note không còn đúng: cập nhật note (và `index.md` nếu thêm/xoá note) trong cùng commit.

## 4. Build

- Mọi lệnh `xcodebuild` (build, test) **phải** thêm `-derivedDataPath build` để sản phẩm nằm trong
  `build/Build/Products/Debug` hoặc `build/Build/Products/Release` tuỳ `-configuration`.
- Không build ra chỗ khác (kể cả DerivedData mặc định `~/Library/Developer/Xcode/DerivedData`) để tránh sinh nhiều bản build thừa.
