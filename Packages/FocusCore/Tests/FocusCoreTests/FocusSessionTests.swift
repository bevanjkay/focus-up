import Foundation
import Testing

@testable import FocusCore

struct FocusSessionTests {
    let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test func remainingCountsDownToZero() {
        let session = FocusSession(start: start, minutes: 15)
        #expect(session.remaining(at: start.addingTimeInterval(60)) == 14 * 60)
        #expect(session.remaining(at: start.addingTimeInterval(20 * 60)) == 0)
    }

    @Test func hasEndedOnlyAfterTheEnd() {
        let session = FocusSession(start: start, minutes: 1)
        #expect(!session.hasEnded(at: start.addingTimeInterval(59)))
        #expect(session.hasEnded(at: start.addingTimeInterval(60)))
    }

    @Test func extendingMovesTheEndAndKeepsTheStart() {
        let session = FocusSession(start: start, minutes: 15).extended(byMinutes: 5)
        #expect(session.end == start.addingTimeInterval(20 * 60))
        #expect(session.start == start)
        #expect(session.totalMinutes == 20)
    }

    @Test(arguments: [
        (59.0, "0:59"), (60.0, "1:00"), (754.0, "12:34"), (3600.0, "1:00:00"), (3661.0, "1:01:01"), (0.4, "0:01"),
    ])
    func formatsRemainingTime(seconds: Double, expected: String) {
        #expect(FocusSession.format(remaining: seconds) == expected)
    }
}
