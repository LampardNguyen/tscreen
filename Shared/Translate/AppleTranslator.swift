import Foundation
import Translation

struct AppleTranslator: Translator {
    func translate(_ texts: [String], from source: Locale.Language?, to target: Locale.Language) async throws -> [String] {
        guard let source else { throw TranslationError(L("error.unknownSourceLanguage")) }
        if source.languageCode == target.languageCode { return texts }
        switch await LanguageAvailability().status(from: source, to: target) {
        case .installed:
            break
        case .supported:
            throw TranslationError(L("error.languagePackMissing", source.minimalIdentifier, target.minimalIdentifier))
        default:
            throw TranslationError(L("error.pairUnsupported", source.minimalIdentifier, target.minimalIdentifier))
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
