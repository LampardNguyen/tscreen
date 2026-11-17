import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureAndTranslate = Self("captureAndTranslate", default: .init(.t, modifiers: [.control, .shift]))
    static let showHistory = Self("showHistory", default: .init(.h, modifiers: [.control, .shift]))
    static let openSettings = Self("openSettings", default: .init(.comma, modifiers: [.control, .shift]))
}

@main
struct TScreenApp: App {
    private let coordinator = AppCoordinator.shared
    // Đọc ngôn ngữ giao diện để menu vẽ lại ngay khi đổi trong Cài đặt.
    @AppStorage(AppLanguage.key) private var appLanguage = "vi"

    init() {
        KeyboardShortcuts.onKeyUp(for: .captureAndTranslate) {
            AppCoordinator.shared.run()
        }
        KeyboardShortcuts.onKeyUp(for: .showHistory) {
            HistoryWindow.show()
        }
        KeyboardShortcuts.onKeyUp(for: .openSettings) {
            AppCoordinator.shared.showSettings()
        }
    }

    var body: some Scene {
        MenuBarExtra("TScreen", systemImage: "text.viewfinder") {
            Button(L("menu.capture")) { coordinator.run() }
            Button(L("menu.history")) { HistoryWindow.show() }
            Divider()
            Button(L("menu.settings")) { coordinator.showSettings() }.keyboardShortcut(",", modifiers: [.control, .shift])
            Button(L("menu.quit")) { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}
