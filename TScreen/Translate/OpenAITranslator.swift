import Foundation

struct OpenAITranslator: Translator {
    let model: String
    /// Mức suy luận của model reasoning (gpt-5…). Rỗng = không gửi tham số (cho model như gpt-4.1).
    let reasoningEffort: String

    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let key = Keychain.get("openAIAPIKey"), !key.isEmpty else {
            throw TranslationError("Chưa nhập OpenAI API key trong Cài đặt.")
        }
        var body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": LLMTranslation.systemPrompt(target: target)],
                ["role": "user", "content": String(decoding: try JSONEncoder().encode(texts), as: UTF8.self)],
            ],
        ]
        if !reasoningEffort.isEmpty { body["reasoning_effort"] = reasoningEffort }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await LLMTranslation.session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode
        guard status == 200 else { throw LLMTranslation.apiError("OpenAI", status: status, data: data) }
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
