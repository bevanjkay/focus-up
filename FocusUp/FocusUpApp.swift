import SwiftUI

@main
struct FocusUpApp: App {
    var body: some Scene {
        MenuBarExtra("Focus Up", systemImage: "circle.dashed.inset.filled") {
            Button("Quit Focus Up") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
