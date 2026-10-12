import FocusCore
import SwiftUI

struct SessionControls: View {
    @Bindable var controller: FocusController
    @State private var isChoosingCustom = false
    @AppStorage("customSessionMinutes") private var customMinutes = 30

    private static let presets = [15, 25, 45, 60]

    var body: some View {
        if let remaining = controller.sessionRemaining {
            HStack {
                Label(FocusSession.format(remaining: remaining), systemImage: "timer")
                    .monospacedDigit()
                Spacer()
                Button("+5 min") { controller.extendSession(byMinutes: 5) }
                Button("End") { controller.endSession() }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Focus for")
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(Self.presets, id: \.self) { minutes in
                        Button("\(minutes)m") { controller.startSession(minutes: minutes) }
                    }
                    Button("Custom…") { isChoosingCustom.toggle() }
                }
                .controlSize(.small)
                if isChoosingCustom {
                    HStack {
                        Stepper("\(customMinutes) min", value: $customMinutes, in: 5...480, step: 5)
                            .monospacedDigit()
                        Spacer()
                        Button("Start") {
                            controller.startSession(minutes: customMinutes)
                            isChoosingCustom = false
                        }
                    }
                }
            }
        }
    }
}
