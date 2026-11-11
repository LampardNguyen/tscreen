import Foundation
import Translation

struct AppleTranslator: Translator {
    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let source else { throw TranslationError("Không nhận diện được ngôn ngữ nguồn.") }
        if source.languageCode == target.languageCode { return texts }
        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            break
        case .supported:
            throw TranslationError("Chưa tải gói ngôn ngữ \(source.minimalIdentifier) → \(target.minimalIdentifier). Tải trong System Settings → General → Language & Region → Translation Languages.")
        default:
            throw TranslationError("Apple Translation không hỗ trợ cặp \(source.minimalIdentifier) → \(target.minimalIdentifier). Hãy chuyển sang Claude hoặc OpenAI trong Cài đặt.")
        }
        let session = TranslationSession(installedSource: source, target: target)
        let requests = texts.enumerated().map { TranslationSession.Request(sourceText: $1, clientIdentifier: String($0)) }
        var result = texts
        for response in try await session.translations(from: requests) {
            if let id = response.clientIdentifier.flatMap(Int.init) { result[id] = response.targetText }
        }
        return result
    }
}
