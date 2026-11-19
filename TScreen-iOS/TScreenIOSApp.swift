import SwiftUI

@main
struct TScreenIOSApp: App {
    // Đổi ngôn ngữ giao diện làm SwiftUI vẽ lại để mọi L(...) cập nhật ngay.
    @AppStorage(AppLanguage.key) private var appLanguage = AppLanguage.fallback

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ScrollView { Text(L("ios.guide.body")).padding() }
                        .navigationTitle(L("ios.tab.guide"))
                }
                .tabItem { Label(L("ios.tab.guide"), systemImage: "questionmark.circle") }
                NavigationStack {
                    SettingsForm().navigationTitle(L("ios.tab.settings"))
                }
                .tabItem { Label(L("ios.tab.settings"), systemImage: "gearshape") }
            }
            .id(appLanguage)
        }
    }
}

/// Form cài đặt iOS, dùng chung khoá UserDefaults/Keychain với bản Mac (`AppSettings.current`).
struct SettingsForm: View {
    @AppStorage(AppLanguage.key) private var appLanguage = AppLanguage.fallback
    @AppStorage("targetLanguage") private var targetLanguage = "vi"
    @AppStorage("engine") private var engine = "apple"
    @AppStorage("claudeModel") private var claudeModel = AppSettings.defaultModel
    @AppStorage("openAIModel") private var openAIModel = AppSettings.defaultOpenAIModel
    @AppStorage("openAIReasoningEffort") private var openAIReasoningEffort = "minimal"
    @AppStorage("customURL") private var customURL = ""
    @AppStorage("customModel") private var customModel = AppSettings.defaultOpenAIModel
    @AppStorage("customReasoningEffort") private var customReasoningEffort = ""
    @AppStorage("fontName") private var fontName = ""
    @State private var apiKey = Keychain.get("claudeAPIKey") ?? ""
    @State private var openAIKey = Keychain.get("openAIAPIKey") ?? ""
    @State private var customKey = Keychain.get("customAPIKey") ?? ""

    private let languages = ["vi": "Tiếng Việt", "en": "English", "ja": "日本語", "zh-Hans": "简体中文", "ko": "한국어", "fr": "Français", "de": "Deutsch"]

    var body: some View {
        Form {
            Section(L("settings.general")) {
                Picker(L("settings.appLanguage"), selection: $appLanguage) {
                    ForEach(AppLanguage.options, id: \.0) { Text($0.1).tag($0.0) }
                }
                Picker(L("settings.targetLanguage"), selection: $targetLanguage) {
                    ForEach(languages.sorted { $0.value < $1.value }, id: \.key) { Text($0.value).tag($0.key) }
                }
                TextField(L("settings.font"), text: $fontName)
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
                    TextField("Base URL", text: $customURL)
                    SecureField("API key", text: $customKey)
                        .onChange(of: customKey) { _, value in Keychain.set("customAPIKey", value) }
                    TextField("Model", text: $customModel)
                    TextField(L("settings.reasoningEffort"), text: $customReasoningEffort)
                }
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
}
