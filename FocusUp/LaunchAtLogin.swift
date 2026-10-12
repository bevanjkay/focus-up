import OSLog
import ServiceManagement

enum LaunchAtLogin {
    private static let logger = Logger(subsystem: "me.bevankay.FocusUp", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                logger.error("Couldn't update launch at login: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
