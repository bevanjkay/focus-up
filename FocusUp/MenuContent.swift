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

            Picker("Style", selection: $controller.style) {
                ForEach(FocusStyle.allCases, id: \.self) { style in
                    Text(style.title).tag(style)
                }
            }

            if controller.style.hidesWindows, controller.wallpapers.needsScreenCapturePermission {
                VStack(alignment: .leading, spacing: 6) {
                    Text(
                        "Your wallpaper comes from an app macOS doesn't let Focus Up read. Allow Screen Recording so Focus Up can show it."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    Button("Allow Screen Recording…") { controller.wallpapers.requestScreenCapturePermission() }
                }
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
        .frame(width: 260)
    }
}
