# Dịch

**Mục đích:** dịch danh sách chuỗi sang ngôn ngữ đích, giữ nguyên số lượng và thứ tự.

**File chính:** `TScreen/Translate/Translator.swift`, `AppleTranslator.swift`, `ClaudeTranslator.swift`, `OpenAITranslator.swift` (cùng thư mục)

**Luồng xử lý**
1. `makeTranslator(settings)` chọn theo `engine`: `"claude"`, `"openai"`, `"custom"`, còn lại là Apple.
2. **Apple:** kiểm tra `LanguageAvailability().status`, dùng `TranslationSession(installedSource:target:)` và `translations(from:)` — chạy trên máy.
3. **Claude / OpenAI:** gửi **một request duy nhất** chứa object `{"1": …, "2": …}` (`keyedInput`, giữ thứ tự id số); `systemPrompt` yêu cầu trả object cùng id, cho phép dồn câu bị OCR cắt vào id đầu nhưng không được bỏ id; `parseKeyed(_:input:truncated:)` map về mảng theo thứ tự input.
   - Claude: `POST https://api.anthropic.com/v1/messages`, model mặc định `claude-sonnet-5-5`. Gửi `tools` + `tool_choice` ép gọi tool `submit_translations` với `input_schema` = `schema(count:)`; `parse` đọc `input` của khối `tool_use`, không có thì dùng text.
   - OpenAI: `POST https://api.openai.com/v1/chat/completions`, model mặc định `gpt-5-mini`, `reasoning_effort` mặc định `minimal` (chỉ gửi khi không rỗng). Gửi `response_format` json_schema strict khi `structuredOutput` (mặc định true).
   - Custom: dùng lại `OpenAITranslator` với `endpoint` = `chatCompletionsURL(base:)` ghép base URL người dùng nhập (vd `https://host/openai-custom/v1`, bỏ `/` thừa ở cuối) với `/chat/completions` (API tương thích OpenAI), `keychainKey` = `customAPIKey`, `provider` = `"Custom"`, `structuredOutput` = false (server tương thích OpenAI chưa chắc hỗ trợ json_schema); `reasoning_effort` mặc định rỗng. URL phải là http/https có host, nếu không báo lỗi.

**Phụ thuộc:** Translation framework, URLSession, API key trong Keychain ([[cai-dat]]).

**Lưu ý/bẫy**
- Dịch là bước chậm nhất (từng đo 12–19s với OpenAI trước khi thêm `reasoning_effort`).
- Chữ trên màn hình là dữ liệu không tin cậy: system prompt cấm làm theo chỉ dẫn nằm trong chuỗi.
- `LLMTranslation.session` là `URLSession` ephemeral; `apiError` chỉ hiện mã trạng thái và `error.message`, không lộ body hay key.
- Lý do dùng id thay vì mảng: OCR hay cắt một câu thành 2 khối, LLM gộp lại → mảng lệch số phần tử và mất cả lô. Với id, id thiếu giữ chữ gốc (có `NSLog`); chỉ lỗi khi không khớp id nào.
- `parseKeyed` phân loại lỗi định dạng: bị cắt (Claude `stop_reason == "max_tokens"`, OpenAI `finish_reason == "length"`), không có `{ }`, JSON hỏng, sai id hoàn toàn. `TranslationError.detail` chứa input + kết quả parse + phản hồi gốc; viewer hiện nút "Chi tiết" mở `ErrorDetailWindow` ([[viewer]]).
- `JSONDecoder` trên macOS mới chấp nhận dấu phẩy thừa (`["a",]`), nên không coi đó là JSON hỏng.
- Engine LLM gửi chữ đã OCR ra ngoài máy — Settings có cảnh báo.

## Liên quan
[[pipeline]] · [[ocr]] · [[cai-dat]]
