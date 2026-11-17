import Foundation

struct ClaudeTranslator: Translator {
    let model: String

    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let key = Keychain.get("claudeAPIKey"), !key.isEmpty else {
            throw TranslationError(L("error.missingAPIKey", "Claude"))
        }
        let system = LLMTranslation.systemPrompt(target: target)
        let input = try LLMTranslation.keyedInput(texts)
        // Ép trả lời qua tool có input_schema đủ mọi id → Claude không trả văn bản tự do và khó bỏ sót id.
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "system": system,
            "messages": [["role": "user", "content": input]],
            "tools": [[
                "name": Self.tool,
                "description": "Submit the translation of every id.",
                "input_schema": LLMTranslation.schema(count: texts.count),
            ]],
            "tool_choice": ["type": "tool", "name": Self.tool],
        ]
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await LLMTranslation.session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode
        guard status == 200 else { throw LLMTranslation.apiError("Claude", status: status, data: data) }
        return try Self.parse(data, input: texts)
    }

    static let tool = "submit_translations"

    /// Lấy mảng bản dịch từ phản hồi Messages API: ưu tiên `input` của khối tool_use, không có thì dùng text.
    static func parse(_ data: Data, input: [String]) throws -> [String] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["content"] as? [[String: Any]] ?? []
        // Serialize lại input của tool thành chuỗi để dùng chung đường parse/báo lỗi với engine khác.
        let toolInput = content.first { $0["type"] as? String == "tool_use" }?["input"]
            .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: [.sortedKeys]) }
            .map { String(decoding: $0, as: UTF8.self) }
        let text = toolInput ?? content.compactMap { $0["text"] as? String }.joined()
        // stop_reason "max_tokens" = bị cắt vì chạm max_tokens.
        return try LLMTranslation.parseKeyed(text, input: input, truncated: json?["stop_reason"] as? String == "max_tokens")
    }
}
