import Foundation

/// A timed stretch of Focus Mode that ends on its own.
public struct FocusSession: Equatable, Codable, Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, minutes: Int) {
        self.init(start: start, end: start.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public var totalMinutes: Int { Int((end.timeIntervalSince(start) / 60).rounded()) }

    public func remaining(at date: Date) -> TimeInterval { max(end.timeIntervalSince(date), 0) }

    public func hasEnded(at date: Date) -> Bool { date >= end }

    public func extended(byMinutes minutes: Int) -> FocusSession {
        FocusSession(start: start, end: end.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    /// `m:ss` or `h:mm:ss`, rounding partial seconds up so the countdown never shows 0:00 early.
    public static func format(remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.up))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }
}
