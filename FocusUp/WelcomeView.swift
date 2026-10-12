import KeyboardShortcuts
import SwiftUI

struct WelcomeView: View {
    @Bindable var controller: FocusController
    @AppStorage("hasCompletedWelcome") private var hasCompletedWelcome = false
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.dashed.inset.filled")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Welcome to Focus Up")
                .font(.title.bold())
            Text("Focus Up keeps the app you're using sharp and blurs everything else. It lives in the menu bar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Form {
                KeyboardShortcuts.Recorder("Toggle Focus Mode:", name: .toggleFocusMode)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LaunchAtLogin.isEnabled = enabled
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 110)

            Button("Get Started") {
                hasCompletedWelcome = true
                controller.isEnabled = true
                dismissWindow()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
        .padding(28)
        .frame(width: 420)
    }
}
