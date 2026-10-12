import CoreGraphics
import Testing

@testable import FocusCore

struct OverlayPlannerTests {
    let safariPID: Int32 = 10
    let notesPID: Int32 = 11
    let musicPID: Int32 = 12

    func plan(
        _ target: FocusTarget?, _ windows: [WindowInfo], pinned: Set<Int32> = [],
        displays: [Display] = [mainDisplay, laptopDisplay]
    ) -> OverlayPlan {
        OverlayPlanner.plan(target: target, windows: windows, displays: displays, pinnedPIDs: pinned, ownPID: ownPID)
    }

    @Test func nothingFocusedHidesOverlay() {
        let result = plan(nil, [window(100, pid: safariPID, CGRect(x: 0, y: 0, width: 800, height: 600))])
        #expect(result == .hidden)
    }

    @Test func focusedAppWithoutVisibleWindowsHidesOverlay() {
        let windows = [window(100, pid: notesPID, CGRect(x: 0, y: 0, width: 800, height: 600))]
        #expect(plan(FocusTarget(pid: safariPID), windows) == .hidden)
    }

    @Test func appScopeOrdersBelowLowestFocusedWindow() {
        let windows = [
            window(101, pid: safariPID, CGRect(x: 0, y: 0, width: 800, height: 600)),
            window(102, pid: safariPID, CGRect(x: 100, y: 100, width: 800, height: 600)),
            window(200, pid: notesPID, CGRect(x: 200, y: 200, width: 800, height: 600)),
        ]
        let result = plan(FocusTarget(pid: safariPID), windows)
        #expect(result.isVisible)
        #expect(result.orderBelowWindow == 102)
    }

    @Test func ignoresOwnFloatingAndTransparentWindows() {
        let windows = [
            window(1, pid: ownPID, CGRect(x: 0, y: 0, width: 3440, height: 1440)),
            window(300, pid: safariPID, CGRect(x: 0, y: 0, width: 300, height: 300), layer: 3),
            window(301, pid: safariPID, CGRect(x: 0, y: 0, width: 300, height: 300), alpha: 0),
        ]
        #expect(plan(FocusTarget(pid: safariPID), windows) == .hidden)
    }

    @Test func windowScopeOrdersBelowMatchingWindow() {
        let key = CGRect(x: 100, y: 100, width: 800, height: 600)
        let windows = [
            window(101, pid: safariPID, CGRect(x: 0, y: 0, width: 800, height: 600)),
            window(102, pid: safariPID, key.offsetBy(dx: 0.5, dy: -0.5)),
            window(103, pid: safariPID, CGRect(x: 500, y: 500, width: 800, height: 600)),
        ]
        #expect(plan(FocusTarget(pid: safariPID, windowFrame: key), windows).orderBelowWindow == 102)
    }

    @Test func windowScopeFallsBackToFrontmostFocusedWindow() {
        let windows = [
            window(200, pid: notesPID, CGRect(x: 0, y: 0, width: 800, height: 600)),
            window(101, pid: safariPID, CGRect(x: 0, y: 0, width: 800, height: 600)),
            window(102, pid: safariPID, CGRect(x: 100, y: 100, width: 800, height: 600)),
        ]
        let target = FocusTarget(pid: safariPID, windowFrame: CGRect(x: 9, y: 9, width: 9, height: 9))
        #expect(plan(target, windows).orderBelowWindow == 101)
    }

    @Test func pinnedWindowsBecomeCutoutsOnTheirDisplay() {
        let windows = [
            window(101, pid: safariPID, CGRect(x: 0, y: 0, width: 800, height: 600)),
            window(400, pid: musicPID, CGRect(x: 3500, y: 200, width: 300, height: 100)),
        ]
        let result = plan(FocusTarget(pid: safariPID), windows, pinned: [musicPID])
        #expect(result.cutouts[mainDisplay.id] == nil)
        #expect(result.cutouts[laptopDisplay.id] == [CGRect(x: 60, y: 962, width: 300, height: 100)])
    }

    @Test func focusedAppIsNeverItsOwnCutout() {
        let windows = [window(101, pid: safariPID, CGRect(x: 0, y: 0, width: 800, height: 600))]
        #expect(plan(FocusTarget(pid: safariPID), windows, pinned: [safariPID]).cutouts.isEmpty)
    }

    @Test func raiseAllNeededWhenFocusedWindowsAreInterleaved() {
        let windows = [
            window(101, pid: safariPID, .zero.insetBy(dx: -10, dy: -10)),
            window(200, pid: notesPID, .zero.insetBy(dx: -10, dy: -10)),
            window(102, pid: safariPID, .zero.insetBy(dx: -10, dy: -10)),
        ]
        #expect(OverlayPlanner.needsRaiseAll(pid: safariPID, windows: windows, ownPID: ownPID))
    }

    @Test func raiseAllNotNeededWhenFocusedWindowsAreOnTop() {
        let windows = [
            window(1, pid: ownPID, .zero.insetBy(dx: -10, dy: -10)),
            window(101, pid: safariPID, .zero.insetBy(dx: -10, dy: -10)),
            window(102, pid: safariPID, .zero.insetBy(dx: -10, dy: -10)),
            window(200, pid: notesPID, .zero.insetBy(dx: -10, dy: -10)),
        ]
        #expect(!OverlayPlanner.needsRaiseAll(pid: safariPID, windows: windows, ownPID: ownPID))
    }
}
