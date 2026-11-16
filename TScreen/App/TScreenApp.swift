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
            Button("Chụp & dịch") { coordinator.run() }
            Button("Lịch sử…") { HistoryWindow.show() }
            Divider()
            Button("Cài đặt…") { coordinator.showSettings() }.keyboardShortcut(",", modifiers: [.control, .shift])
            Button("Thoát") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}
