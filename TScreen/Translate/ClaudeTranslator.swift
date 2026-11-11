import Foundation

struct ClaudeTranslator: Translator {
    let model: String

    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let key = Keychain.get("claudeAPIKey"), !key.isEmpty else {
            throw TranslationError("Chưa nhập Claude API key trong Cài đặt.")
        }
        let system = LLMTranslation.systemPrompt(target: target)
        let input = String(decoding: try JSONEncoder().encode(texts), as: UTF8.self)
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "system": system,
            "messages": [["role": "user", "content": input]],
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
        return try Self.parse(data, count: texts.count)
    }

    /// Lấy mảng bản dịch từ phản hồi Messages API.
    static func parse(_ data: Data, count: Int) throws -> [String] {
        struct Message: Decodable {
            struct Block: Decodable { let type: String; let text: String? }
            let content: [Block]
        }
        let text = try JSONDecoder().decode(Message.self, from: data).content.compactMap(\.text).joined()
        return try LLMTranslation.parseArray(text, count: count)
    }
}
