import FocusCore
import SwiftUI

struct MenuContent: View {
    @Bindable var controller: FocusController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Focus Mode", isOn: $controller.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)

            SessionControls(controller: controller)

            Divider()

            Picker("Scope", selection: $controller.scope) {
                ForEach(FocusScope.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            if controller.needsAccessibilityPermission {
                PermissionNote(
                    message: """
                        Window scope needs Accessibility permission to follow the focused window. \
                        Until then, Focus Up keeps the whole app sharp.
                        """,
                    action: "Allow Accessibility…", perform: AXFocusMonitor.requestTrust)
            }

            Picker("Style", selection: $controller.style) {
                ForEach(FocusStyle.allCases, id: \.self) { Text($0.title).tag($0) }
            }

            if controller.style.hidesWindows, controller.wallpapers.needsScreenCapturePermission {
                PermissionNote(
                    message: """
                        Your wallpaper comes from an app macOS doesn't let Focus Up read. \
                        Allow Screen Recording so Focus Up can show it.
                        """,
                    action: "Allow Screen Recording…", perform: controller.wallpapers.requestScreenCapturePermission)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Intensity")
                    .foregroundStyle(.secondary)
                Slider(value: $controller.intensity, in: 0...1)
            }

            Divider()

            HStack {
                Button("Settings…") {
                    openWindow(id: WindowID.settings)
                    NSApp.activate()
                }
                .keyboardShortcut(",")
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 280)
    }
}

struct PermissionNote: View {
    let message: LocalizedStringResource
    let action: LocalizedStringResource
    let perform: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(String(localized: action), action: perform)
        }
    }
}
