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

## 5. Nguyên tắc hành vi khi viết code

Các nguyên tắc nhằm giảm những lỗi thường gặp của LLM khi viết code. Kết hợp với các quy định riêng của project khi cần.

**Đánh đổi:** Các nguyên tắc này ưu tiên sự thận trọng hơn tốc độ. Với task đơn giản, hãy tự cân nhắc.

### 5.1. Suy nghĩ trước khi code

**Đừng giả định. Đừng giấu sự bối rối. Nêu rõ các đánh đổi.**

Trước khi triển khai:
- Nêu rõ các giả định của mình. Nếu không chắc, hãy hỏi.
- Nếu có nhiều cách hiểu, trình bày tất cả — đừng âm thầm chọn một.
- Nếu có cách đơn giản hơn, hãy nói ra. Phản biện khi cần thiết.
- Nếu có điều gì chưa rõ, dừng lại. Chỉ ra điểm gây khó hiểu. Hỏi.

### 5.2. Ưu tiên sự đơn giản

**Viết lượng code tối thiểu để giải quyết vấn đề. Không thêm gì mang tính phỏng đoán.**

- Không thêm tính năng ngoài yêu cầu.
- Không tạo abstraction cho code chỉ dùng một lần.
- Không thêm "tính linh hoạt" hay "khả năng cấu hình" khi không được yêu cầu.
- Không xử lý lỗi cho những tình huống không thể xảy ra.
- Nếu viết 200 dòng mà có thể chỉ cần 50, hãy viết lại.

Tự hỏi: "Một kỹ sư senior có cho rằng chỗ này phức tạp quá mức không?" Nếu có, hãy đơn giản hoá.

### 5.3. Thay đổi có chọn lọc

**Chỉ chạm vào những gì bắt buộc. Chỉ dọn dẹp phần do chính mình gây ra.**

Khi sửa code có sẵn:
- Không "cải thiện" code, comment hay format ở các phần lân cận.
- Không refactor những thứ không bị lỗi.
- Giữ đúng style hiện có, kể cả khi bạn muốn làm khác.
- Nếu thấy dead code không liên quan, hãy nhắc tới — đừng xoá.

Khi thay đổi của bạn tạo ra phần thừa:
- Xoá import/biến/hàm mà CHÍNH thay đổi của bạn khiến chúng không còn được dùng.
- Không xoá dead code có sẵn từ trước trừ khi được yêu cầu.

Phép thử: Mỗi dòng thay đổi phải truy ngược được trực tiếp về yêu cầu của người dùng.

### 5.4. Thực thi hướng mục tiêu

**Xác định tiêu chí thành công. Lặp lại cho đến khi được xác minh.**

Chuyển task thành các mục tiêu có thể kiểm chứng:
- "Thêm validation" → "Viết test cho input không hợp lệ, rồi làm cho test pass"
- "Sửa bug" → "Viết test tái hiện bug, rồi làm cho test pass"
- "Refactor X" → "Đảm bảo test pass cả trước và sau khi refactor"

Với task nhiều bước, nêu kế hoạch ngắn gọn:
```
1. [Bước] → kiểm tra: [cách kiểm tra]
2. [Bước] → kiểm tra: [cách kiểm tra]
3. [Bước] → kiểm tra: [cách kiểm tra]
```

Tiêu chí thành công rõ ràng giúp tự lặp lại độc lập. Tiêu chí mơ hồ ("làm cho chạy được") đòi hỏi phải hỏi lại liên tục.

---

**Các nguyên tắc này đang phát huy tác dụng khi:** diff ít thay đổi thừa hơn, ít phải viết lại do phức tạp quá mức, và các câu hỏi làm rõ được đặt ra trước khi triển khai thay vì sau khi đã mắc lỗi.
