import SwiftUI

struct MenuContent: View {
    @Bindable var controller: FocusController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Focus Mode", isOn: $controller.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Intensity")
                    .foregroundStyle(.secondary)
                Slider(value: $controller.intensity, in: 0...1)
            }

            Divider()

            Button("Quit Focus Up") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 260)
    }
}
