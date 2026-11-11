import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureAndTranslate = Self("captureAndTranslate", default: .init(.t, modifiers: [.control, .shift]))
}

@main
struct TScreenApp: App {
    private let coordinator = AppCoordinator.shared

    init() {
        KeyboardShortcuts.onKeyUp(for: .captureAndTranslate) {
            AppCoordinator.shared.run()
        }
    }

    var body: some Scene {
        MenuBarExtra("TScreen", systemImage: "text.viewfinder") {
            Button("Chụp & dịch") { coordinator.run() }
            Divider()
            Button("Cài đặt…") { coordinator.showSettings() }.keyboardShortcut(",")
            Button("Thoát") { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}
