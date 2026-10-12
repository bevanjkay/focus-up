import OSLog
import UserNotifications

enum SessionNotifier {
    private static let logger = Logger(subsystem: "me.bevankay.FocusUp", category: "Sessions")

    static func requestAuthorisation() {
        Task {
            do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            } catch {
                logger.error("Notification authorisation failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    static func notifyCompletion(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Focus session complete")
        content.body = String(localized: "You focused for \(minutes) minutes.")
        content.sound = .default
        let request = UNNotificationRequest(identifier: "session-complete", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
