# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## 2026-11-19

- Thêm bản iOS (branch `ios`): target `TScreen-iOS` (iOS 26.0+), App Intent "Dịch bằng TScreen" nhận ảnh chụp màn hình và trả ảnh đã dịch, dùng với Phím tắt + AssistiveTouch; app có tab Hướng dẫn và Cài đặt, không có lịch sử.
- Tách code dùng chung sang `Shared/` (OCR, Translate, Render, `AppSettings`, Keychain, L10n, i18n, `detectLanguage`); test i18n quét cả `Shared` và `TScreen-iOS`.
- iOS: viết lại màn hình Hướng dẫn chi tiết từng bước (tạo phím tắt trong app Phím tắt, gán AssistiveTouch, cài đặt dịch, Chạm vào mặt sau/nút Tác vụ, xử lý sự cố) cho vi/en/ja.
- iOS: intent "Dịch bằng TScreen" có `parameterSummary` để Phím tắt tự nối ảnh chụp màn hình từ bước trước (trước đó ô Ảnh chỉ mở trình chọn tệp); cập nhật bước 6 hướng dẫn.

## 2026-11-18

- Vẽ ảnh: khối có bản dịch giống chữ gốc (bỏ qua khoảng trắng thừa, không phân biệt hoa/thường) giữ nguyên ảnh gốc, không tô nền/vẽ lại, tránh vỡ chữ. Test `testComposeSkipsUnchangedBlocks`.

## 2026-11-17

- Đa ngôn ngữ giao diện Việt / Anh / Nhật (mặc định Tiếng Việt): chọn ở Cài đặt → Chung → "Ngôn ngữ giao diện" (`appLanguage`), đổi là áp dụng ngay không cần mở lại app. Chuỗi giao diện lưu theo khoá (vd. `menu.capture`), mỗi ngôn ngữ một file `TScreen/Resources/i18n/{vi,en,ja}.json`; test `testLocalizationKeysComplete` báo lỗi khi code dùng khoá không có trong file, các file lệch khoá hoặc lệch tham số `%@`/`%d`.

- Lịch sử: thêm nút bút chì ở mỗi dòng để đặt/sửa tiêu đề gợi nhớ (lưu trong `meta.json`, để trống = bỏ tiêu đề); ô tìm kiếm khớp cả tiêu đề.

## 2026-11-16

- Phím tắt mở Cài đặt đổi từ ⌘, (chỉ khi menu đang mở) thành phím tắt toàn cục ⌃⇧, (`KeyboardShortcuts.Name.openSettings`); menu hiển thị đúng phím mới.

- Viewer có `.moveToActiveSpace`: bấm item lịch sử có viewer đang mở ở Desktop khác thì viewer chuyển sang Desktop hiện tại.

- Cửa sổ Lịch sử có nút "Xoá tất cả" cạnh ô tìm kiếm (hỏi xác nhận trước khi xoá).

- Lịch sử: bấm item đang có viewer mở (kể cả viewer vừa chụp) thì chỉ đưa viewer đó lên trước, không tạo viewer trùng.

- Lịch sử: con trỏ đổi thành bàn tay khi hover item; cửa sổ mở ở Desktop đang dùng thay vì nhảy về Desktop mở lần đầu (`.moveToActiveSpace`).

- Cài đặt → Quyền: nút "Mở System Settings → Screen Recording" luôn hiển thị, mở thẳng trang cấp quyền ghi màn hình.

- Lịch sử dịch: mỗi lần dịch xong tự lưu ảnh đã dịch + chữ gốc/chữ dịch vào `~/Library/Application Support/TScreen/History` (tối đa 200 bản, "Thử lại" thay bản cũ). Cửa sổ "Lịch sử dịch" mở bằng ⌃⇧H hoặc menu "Lịch sử…": tìm kiếm không phân biệt hoa thường/dấu, thumbnail, nút xoá từng item, bấm item mở lại viewer. Cài đặt có phím tắt, công tắc lưu lịch sử (mặc định bật) và nút "Xoá tất cả lịch sử".

- Lỗi "Engine dịch trả về kết quả không đúng định dạng" được tách thành: bị cắt do hết token (đọc `stop_reason`/`finish_reason`), không có mảng JSON, JSON hỏng, sai số khối (nhận X, cần Y). Viewer có nút "Chi tiết" mở cửa sổ lớn xem input, kết quả đã parse và phản hồi gốc, kèm nút sao chép.
- Engine LLM gửi và nhận dạng object có id (`{"1": …, "2": …}`) thay vì mảng: khi OCR cắt một câu thành nhiều khối mà model gộp lại, lô dịch không còn bị bỏ cả lô; id thiếu thì giữ chữ gốc. OpenAI dùng structured output `json_schema` strict, Claude dùng tool use bắt buộc (`submit_translations`), schema bắt buộc đủ mọi id. Engine Custom chỉ dùng định dạng id qua prompt (không gửi `response_format`).

## 2026-11-13

- Chụp "đóng băng" màn hình ngay khi bấm phím tắt, trước khi mở overlay chọn vùng; overlay hiện ảnh đã chụp và vùng chọn được cắt từ ảnh đó, nên popup/tooltip hiện do hover trên browser không còn bị mất.
- Thêm engine dịch "Custom (tương thích OpenAI)": API URL, API key (Keychain `customAPIKey`), model và reasoning effort riêng; dùng lại `OpenAITranslator` với endpoint tuỳ chỉnh.
- Engine Custom chỉ cần nhập base URL (vd `…/openai-custom/v1`); app tự ghép thêm `/chat/completions`.
- Settings: thêm icon `?` sau "Base URL", hover hiện gợi ý định dạng và ví dụ; cảnh báo gửi dữ liệu hiện đúng host kể cả khi URL có khoảng trắng thừa.

## 2026-11-12

- Thêm rule build vào `CLAUDE.md`: luôn dùng `-derivedDataPath build`, sản phẩm nằm trong `build/Build/Products/{Debug,Release}`.
- Khi dịch qua API (OpenAI, Claude) bị lỗi (lỗi API hoặc mạng), viewer hiện nút "Thử lại" để gọi lại API mà không cần chụp/OCR lại.
- Xoá nút phóng to / thu nhỏ khỏi thanh công cụ viewer (phím ⌘+ / ⌘− vẫn còn).
- Vẽ bốn dấu góc chữ L ở bốn góc viewer để biết có thể kéo đổi kích thước.
- Kéo ở bốn góc viewer để đổi kích thước, luôn giữ tỉ lệ ngang dọc; không resize theo một chiều.
- Thêm `CLAUDE.md` với rule làm việc cho project.
- Thêm `graphify/` gồm `index.md` và 8 note cho các chức năng hiện có.

## [Unreleased]

## [0.1.0]

### Added

- Menu bar app with a global hotkey and drag-to-select region capture
- OCR with Apple Vision, grouped into paragraphs
- Automatic source-language detection
- Translation engines: Apple Translation, Claude, OpenAI
- In-place rendering of translated text with sampled colours and fitted font size
- Borderless viewer with a floating toolbar (toggle, zoom, copy, save, pin)
- Settings window: hotkey, target language, engine, API keys, font
- Per-step timing display
- App icon
