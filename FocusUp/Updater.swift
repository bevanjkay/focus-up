import AppKit
import Observation
import Sparkle

/// Sparkle updates, fed from the `appcast.xml` attached to the latest GitHub Release.
@MainActor
@Observable
final class Updater {
    static let shared = Updater()

    @ObservationIgnored private let controller = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    var automaticallyChecksForUpdates: Bool {
        get {
            access(keyPath: \.automaticallyChecksForUpdates)
            return controller.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.automaticallyChecksForUpdates) {
                controller.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    func checkForUpdates() {
        // Focus Up has no Dock icon, so bring it forward for Sparkle's window.
        NSApp.activate()
        controller.checkForUpdates(nil)
    }
}
