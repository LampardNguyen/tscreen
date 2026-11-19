import SwiftUI
import KeyboardShortcuts

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
    @AppStorage(HistoryStore.enabledKey) private var saveHistory = true
    // Đổi giá trị này làm SwiftUI vẽ lại toàn bộ form, nên mọi L(...) bên dưới cập nhật ngay.
    @AppStorage(AppLanguage.key) private var appLanguage = "vi"

    private let languages = ["vi": "Tiếng Việt", "en": "English", "ja": "日本語", "zh-Hans": "简体中文", "ko": "한국어", "fr": "Français", "de": "Deutsch"]

    private var provider: String {
        switch engine {
        case "claude": "Anthropic"
        case "custom": URL(string: customURL.trimmingCharacters(in: .whitespaces))?.host ?? L("settings.customAPI")
        default: "OpenAI"
        }
    }

    var body: some View {
        Form {
            Section(L("settings.general")) {
                Picker(L("settings.appLanguage"), selection: $appLanguage) {
                    ForEach(AppLanguage.options, id: \.0) { Text($0.1).tag($0.0) }
                }
                KeyboardShortcuts.Recorder(L("settings.captureShortcut"), name: .captureAndTranslate)
                Picker(L("settings.targetLanguage"), selection: $targetLanguage) {
                    ForEach(languages.sorted { $0.value < $1.value }, id: \.key) { Text($0.value).tag($0.key) }
                }
                TextField(L("settings.font"), text: $fontName)
            }
            Section(L("settings.history")) {
                KeyboardShortcuts.Recorder(L("settings.historyShortcut"), name: .showHistory)
                Toggle(L("settings.saveHistory", HistoryStore.shared.limit), isOn: $saveHistory)
                Button(L("settings.deleteAllHistory"), role: .destructive) { HistoryStore.shared.deleteAll() }
            }
            Section(L("settings.engine")) {
                Picker("Engine", selection: $engine) {
                    Text("Apple Translation (offline)").tag("apple")
                    Text("Claude").tag("claude")
                    Text("OpenAI").tag("openai")
                    Text(L("settings.engineCustom")).tag("custom")
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
                    TextField(L("settings.reasoningEffort"), text: $openAIReasoningEffort)
                }
                if engine == "custom" {
                    TextField(text: $customURL) {
                        HStack(spacing: 4) {
                            Text("Base URL")
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                                .help(L("settings.baseURLHelp", "https://<your-domain>/openai-custom/v1"))
                        }
                    }
                    SecureField("API key", text: $customKey)
                        .onChange(of: customKey) { _, value in Keychain.set("customAPIKey", value) }
                    TextField("Model", text: $customModel)
                    TextField(L("settings.reasoningEffort"), text: $customReasoningEffort)
                }
                if engine != "apple" {
                    Label(L("settings.privacyWarning", provider),
                          systemImage: "icloud.and.arrow.up")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
            Section(L("settings.permissions")) {
                LabeledContent("Screen Recording") {
                    if hasPermission {
                        Label(L("settings.granted"), systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Button(L("settings.grantAccess")) {
                            CGRequestScreenCaptureAccess()
                            hasPermission = CGPreflightScreenCaptureAccess()
                        }
                    }
                }
                // Luôn hiện: app ký ad-hoc nên mỗi bản build mới có thể mất quyền, cần vào System Settings xoá/bật lại.
                Button(L("settings.openScreenRecording")) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
    }
}
