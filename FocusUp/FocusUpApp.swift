import SwiftUI

@main
struct FocusUpApp: App {
    private let controller = FocusController.shared
    private let hasCompletedWelcome = UserDefaults.standard.bool(forKey: "hasCompletedWelcome")

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            Image(systemName: controller.isEnabled ? "circle.dashed.inset.filled" : "circle.dashed")
        }
        .menuBarExtraStyle(.window)

        // Focus Up's own windows float above the Overlay so they are never blurred.
        Window("Focus Up Settings", id: WindowID.settings) {
            SettingsView(controller: controller)
        }
        .windowResizability(.contentSize)
        .windowLevel(.floating)
        .defaultLaunchBehavior(.suppressed)

        Window("Welcome to Focus Up", id: WindowID.welcome) {
            WelcomeView(controller: controller)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowLevel(.floating)
        .defaultLaunchBehavior(hasCompletedWelcome ? .suppressed : .presented)
    }
}

enum WindowID {
    static let settings = "settings"
    static let welcome = "welcome"
}
