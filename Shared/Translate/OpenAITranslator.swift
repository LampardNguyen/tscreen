import Foundation

struct OpenAITranslator: Translator {
    let model: String
    /// Mức suy luận của model reasoning (gpt-5…). Rỗng = không gửi tham số (cho model như gpt-4.1).
    let reasoningEffort: String
    /// Endpoint Chat Completions; engine Custom dùng URL riêng, tương thích OpenAI.
    var endpoint = "https://api.openai.com/v1/chat/completions"
    /// Khoá Keychain chứa API key.
    var keychainKey = "openAIAPIKey"
    /// Tên hiển thị trong thông báo lỗi.
    var provider = "OpenAI"
    /// Gửi `response_format` json_schema strict. Tắt cho engine Custom vì server tương thích OpenAI chưa chắc hỗ trợ.
    var structuredOutput = true

    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let key = Keychain.get(keychainKey), !key.isEmpty else {
            throw TranslationError(L("error.missingAPIKey", provider))
        }
        guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespaces)),
              ["http", "https"].contains(url.scheme?.lowercased()), url.host != nil else {
            throw TranslationError(L("error.invalidAPIURL", provider))
        }
        var body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": LLMTranslation.systemPrompt(target: target)],
                ["role": "user", "content": try LLMTranslation.keyedInput(texts)],
            ],
        ]
        if !reasoningEffort.isEmpty { body["reasoning_effort"] = reasoningEffort }
        // Structured output strict: API đảm bảo JSON đúng schema (đủ mọi id, đều là chuỗi).
        if structuredOutput {
            body["response_format"] = ["type": "json_schema", "json_schema": [
                "name": "translations", "strict": true, "schema": LLMTranslation.schema(count: texts.count),
            ] as [String: Any]]
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await LLMTranslation.session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode
        guard status == 200 else { throw LLMTranslation.apiError(provider, status: status, data: data) }
        return try Self.parse(data, input: texts)
    }

    /// Lấy mảng bản dịch từ phản hồi Chat Completions API.
    static func parse(_ data: Data, input: [String]) throws -> [String] {
        struct Completion: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? }
                let message: Message
                let finish_reason: String?
            }
            let choices: [Choice]
        }
        let choice = try JSONDecoder().decode(Completion.self, from: data).choices.first
        // finish_reason "length" = bị cắt vì chạm giới hạn token.
        return try LLMTranslation.parseKeyed(choice?.message.content ?? "", input: input,
                                             truncated: choice?.finish_reason == "length")
    }
}
