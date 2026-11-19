import Foundation

struct AppSettings {
    static let defaultModel = "claude-sonnet-5-5"
    static let defaultOpenAIModel = "gpt-5-mini"
    var targetLanguage: Locale.Language
    var engine: String
    var claudeModel: String
    var openAIModel: String
    var openAIReasoningEffort: String
    var customURL: String
    var customModel: String
    var customReasoningEffort: String
    var fontName: String

    static var current: AppSettings {
        let d = UserDefaults.standard
        return AppSettings(
            targetLanguage: Locale.Language(identifier: d.string(forKey: "targetLanguage") ?? "vi"),
            engine: d.string(forKey: "engine") ?? "apple",
            claudeModel: d.string(forKey: "claudeModel") ?? defaultModel,
            openAIModel: d.string(forKey: "openAIModel") ?? defaultOpenAIModel,
            openAIReasoningEffort: d.string(forKey: "openAIReasoningEffort") ?? "minimal",
            customURL: d.string(forKey: "customURL") ?? "",
            customModel: d.string(forKey: "customModel") ?? defaultOpenAIModel,
            customReasoningEffort: d.string(forKey: "customReasoningEffort") ?? "",
            fontName: d.string(forKey: "fontName") ?? "")
    }
}
