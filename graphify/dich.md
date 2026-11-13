# Dịch

**Mục đích:** dịch danh sách chuỗi sang ngôn ngữ đích, giữ nguyên số lượng và thứ tự.

**File chính:** `TScreen/Translate/Translator.swift`, `AppleTranslator.swift`, `ClaudeTranslator.swift`, `OpenAITranslator.swift` (cùng thư mục)

**Luồng xử lý**
1. `makeTranslator(settings)` chọn theo `engine`: `"claude"`, `"openai"`, `"custom"`, còn lại là Apple.
2. **Apple:** kiểm tra `LanguageAvailability().status`, dùng `TranslationSession(installedSource:target:)` và `translations(from:)` — chạy trên máy.
3. **Claude / OpenAI:** gửi **một request duy nhất** chứa mảng JSON các chuỗi; `LLMTranslation.systemPrompt` yêu cầu trả mảng JSON cùng độ dài; `parseArray(_:count:)` kiểm tra.
   - Claude: `POST https://api.anthropic.com/v1/messages`, model mặc định `claude-sonnet-5-5`.
   - OpenAI: `POST https://api.openai.com/v1/chat/completions`, model mặc định `gpt-5-mini`, `reasoning_effort` mặc định `minimal` (chỉ gửi khi không rỗng).
   - Custom: dùng lại `OpenAITranslator` với `endpoint` = `chatCompletionsURL(base:)` ghép base URL người dùng nhập (vd `https://host/openai-custom/v1`, bỏ `/` thừa ở cuối) với `/chat/completions` (API tương thích OpenAI), `keychainKey` = `customAPIKey`, `provider` = `"Custom"`; `reasoning_effort` mặc định rỗng. URL phải là http/https có host, nếu không báo lỗi.

**Phụ thuộc:** Translation framework, URLSession, API key trong Keychain ([[cai-dat]]).

**Lưu ý/bẫy**
- Dịch là bước chậm nhất (từng đo 12–19s với OpenAI trước khi thêm `reasoning_effort`).
- Chữ trên màn hình là dữ liệu không tin cậy: system prompt cấm làm theo chỉ dẫn nằm trong chuỗi.
- `LLMTranslation.session` là `URLSession` ephemeral; `apiError` chỉ hiện mã trạng thái và `error.message`, không lộ body hay key.
- Engine LLM gửi chữ đã OCR ra ngoài máy — Settings có cảnh báo.

## Liên quan
[[pipeline]] · [[ocr]] · [[cai-dat]]
