import SwiftUI

@main
struct FocusUpApp: App {
    private let controller = FocusController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            Image(systemName: controller.isEnabled ? "circle.dashed.inset.filled" : "circle.dashed")
        }
        .menuBarExtraStyle(.window)
    }
}
