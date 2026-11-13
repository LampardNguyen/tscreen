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

    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let key = Keychain.get(keychainKey), !key.isEmpty else {
            throw TranslationError("Chưa nhập \(provider) API key trong Cài đặt.")
        }
        guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespaces)),
              ["http", "https"].contains(url.scheme?.lowercased()), url.host != nil else {
            throw TranslationError("API URL của \(provider) không hợp lệ.")
        }
        var body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": LLMTranslation.systemPrompt(target: target)],
                ["role": "user", "content": String(decoding: try JSONEncoder().encode(texts), as: UTF8.self)],
            ],
        ]
        if !reasoningEffort.isEmpty { body["reasoning_effort"] = reasoningEffort }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await LLMTranslation.session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode
        guard status == 200 else { throw LLMTranslation.apiError(provider, status: status, data: data) }
        return try Self.parse(data, count: texts.count)
    }

    /// Lấy mảng bản dịch từ phản hồi Chat Completions API.
    static func parse(_ data: Data, count: Int) throws -> [String] {
        struct Completion: Decodable {
            struct Choice: Decodable { struct Message: Decodable { let content: String? }; let message: Message }
            let choices: [Choice]
        }
        let text = try JSONDecoder().decode(Completion.self, from: data).choices.first?.message.content ?? ""
        return try LLMTranslation.parseArray(text, count: count)
    }
}
