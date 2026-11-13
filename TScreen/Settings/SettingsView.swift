import SwiftUI
import KeyboardShortcuts

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

struct SettingsView: View {
    @AppStorage("targetLanguage") private var targetLanguage = "vi"
    @AppStorage("engine") private var engine = "apple"
    @AppStorage("claudeModel") private var claudeModel = AppSettings.defaultModel
    @AppStorage("fontName") private var fontName = ""
    @AppStorage("openAIModel") private var openAIModel = AppSettings.defaultOpenAIModel
    @AppStorage("openAIReasoningEffort") private var openAIReasoningEffort = "minimal"
    @AppStorage("customURL") private var customURL = ""
    @AppStorage("customModel") private var customModel = AppSettings.defaultOpenAIModel
    @AppStorage("customReasoningEffort") private var customReasoningEffort = ""
    @State private var openAIKey = Keychain.get("openAIAPIKey") ?? ""
    @State private var customKey = Keychain.get("customAPIKey") ?? ""
    @State private var apiKey = Keychain.get("claudeAPIKey") ?? ""
    @State private var hasPermission = CGPreflightScreenCaptureAccess()

    private let languages = ["vi": "Tiếng Việt", "en": "English", "ja": "日本語", "zh-Hans": "简体中文", "ko": "한국어", "fr": "Français", "de": "Deutsch"]

    private var provider: String {
        switch engine {
        case "claude": "Anthropic"
        case "custom": URL(string: customURL.trimmingCharacters(in: .whitespaces))?.host ?? "API custom"
        default: "OpenAI"
        }
    }

    var body: some View {
        Form {
            Section("Chung") {
                KeyboardShortcuts.Recorder("Phím tắt chụp & dịch", name: .captureAndTranslate)
                Picker("Dịch sang", selection: $targetLanguage) {
                    ForEach(languages.sorted { $0.value < $1.value }, id: \.key) { Text($0.value).tag($0.key) }
                }
                TextField("Font chữ (để trống = font hệ thống)", text: $fontName)
            }
            Section("Engine dịch") {
                Picker("Engine", selection: $engine) {
                    Text("Apple Translation (offline)").tag("apple")
                    Text("Claude").tag("claude")
                    Text("OpenAI").tag("openai")
                    Text("Custom (tương thích OpenAI)").tag("custom")
                }
                if engine == "claude" {
                    SecureField("Claude API key", text: $apiKey)
                        .onChange(of: apiKey) { _, value in Keychain.set("claudeAPIKey", value) }
                    TextField("Model", text: $claudeModel)
                }
                if engine == "openai" {
                    SecureField("OpenAI API key", text: $openAIKey)
                        .onChange(of: openAIKey) { _, value in Keychain.set("openAIAPIKey", value) }
                    TextField("Model", text: $openAIModel)
                    TextField("Reasoning effort (để trống nếu model không hỗ trợ)", text: $openAIReasoningEffort)
                }
                if engine == "custom" {
                    TextField(text: $customURL) {
                        HStack(spacing: 4) {
                            Text("Base URL")
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                                .help("Base URL của API tương thích OpenAI, kết thúc bằng /v1. App tự thêm /chat/completions.\nVí dụ: https://sgp-linkto.betrend.com/openai-custom/v1")
                        }
                    }
                    SecureField("API key", text: $customKey)
                        .onChange(of: customKey) { _, value in Keychain.set("customAPIKey", value) }
                    TextField("Model", text: $customModel)
                    TextField("Reasoning effort (để trống nếu model không hỗ trợ)", text: $customReasoningEffort)
                }
                if engine != "apple" {
                    Label("Chữ nhận diện được trong vùng chụp sẽ được gửi tới máy chủ của \(provider). Tránh chụp vùng có mật khẩu, mã OTP hoặc dữ liệu nhạy cảm. Ảnh không được gửi đi.",
                          systemImage: "icloud.and.arrow.up")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
            Section("Quyền") {
                LabeledContent("Screen Recording") {
                    if hasPermission {
                        Label("Đã cấp", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button("Cấp quyền…") {
                            CGRequestScreenCaptureAccess()
                            hasPermission = CGPreflightScreenCaptureAccess()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
    }
}
