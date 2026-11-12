# OCR

**Mục đích:** nhận diện chữ trong ảnh và gom thành các khối (đoạn văn) kèm vị trí.

**File chính:** `TScreen/OCR/TextRecognizer.swift`, `TScreen/OCR/TextBlock.swift`

**Luồng xử lý**
1. `TextRecognizer.recognize` chạy `RecognizeDocumentsRequest` (macOS 26) với ngôn ngữ `ja-JP`, `en-US`.
2. Mỗi paragraph của `observation.document` thành một `TextBlock`; nếu không có paragraph thì mỗi dòng là một khối.
3. `boundingBox.toImageCoordinates(size, origin: .upperLeft)` đổi sang pixel gốc trên-trái.
4. `TextBlock.joinLines` nối các dòng: không chèn dấu cách giữa hai ký tự CJK, còn lại chèn dấu cách.

**Phụ thuộc:** Vision.

**Lưu ý/bẫy**
- `TextBlock` gồm `text`, `rect` (pixel, gốc trên-trái), `lineHeight` — `lineHeight` quyết định cỡ chữ tối đa khi vẽ ([[ve-anh]]).
- Chỉ hỗ trợ chữ ngang.

## Liên quan
[[pipeline]] · [[dich]] · [[ve-anh]]
