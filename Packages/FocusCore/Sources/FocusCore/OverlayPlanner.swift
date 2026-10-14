import CoreGraphics

public struct OverlayPlan: Equatable, Sendable {
    public var isVisible: Bool
    /// The window every Overlay is ordered directly below.
    public var orderBelowWindow: Int?
    /// Cut-out rects per display ID, in display-local AppKit coordinates.
    public var cutouts: [UInt32: [CGRect]]
    /// Frames of the windows in front of the Overlay per display ID, in display-local AppKit coordinates.
    public var sharpRects: [UInt32: [CGRect]] = [:]

    public static let hidden = OverlayPlan(isVisible: false, orderBelowWindow: nil, cutouts: [:])
}

public enum OverlayPlanner {
    private static let frameMatchTolerance: CGFloat = 2

    /// - Parameter windows: on-screen windows, front to back.
    public static func plan(
        target: FocusTarget?, windows: [WindowInfo], displays: [Display], pinnedPIDs: Set<Int32>, ownPID: Int32
    ) -> OverlayPlan {
        let candidates = normalWindows(windows, ownPID: ownPID)
        guard let target else { return .hidden }
        let focused = candidates.filter { $0.pid == target.pid }
        guard let anchor = anchorWindow(for: target, in: focused) else { return .hidden }

        let pinnedFrames = candidates.filter { pinnedPIDs.contains($0.pid) && $0.pid != target.pid }.map(\.frame)
        let sharpFrames = candidates.prefix { $0.number != anchor.number }.map(\.frame) + [anchor.frame]
        return OverlayPlan(
            isVisible: true, orderBelowWindow: anchor.number, cutouts: localRects(pinnedFrames, on: displays),
            sharpRects: localRects(sharpFrames, on: displays))
    }

    /// Whether another app's window sits between the Focused App's windows, so Raise-all is needed.
    public static func needsRaiseAll(pid: Int32, windows: [WindowInfo], ownPID: Int32) -> Bool {
        let candidates = normalWindows(windows, ownPID: ownPID)
        guard let lowest = candidates.lastIndex(where: { $0.pid == pid }) else { return false }
        return candidates[...lowest].contains { $0.pid != pid }
    }

    private static func localRects(_ frames: [CGRect], on displays: [Display]) -> [UInt32: [CGRect]] {
        var rects: [UInt32: [CGRect]] = [:]
        for display in displays {
            let local = CutoutGeometry.localRects(for: frames, in: display.frame)
            if !local.isEmpty { rects[display.id] = local }
        }
        return rects
    }

    private static func normalWindows(_ windows: [WindowInfo], ownPID: Int32) -> [WindowInfo] {
        windows.filter { $0.layer == 0 && $0.alpha > 0 && $0.pid != ownPID && !$0.frame.isEmpty }
    }

    private static func anchorWindow(for target: FocusTarget, in focused: [WindowInfo]) -> WindowInfo? {
        guard let windowFrame = target.windowFrame else { return focused.last }
        return focused.first { matches($0.frame, windowFrame) } ?? focused.first
    }

    private static func matches(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) <= frameMatchTolerance && abs(a.minY - b.minY) <= frameMatchTolerance
            && abs(a.width - b.width) <= frameMatchTolerance && abs(a.height - b.height) <= frameMatchTolerance
    }
}
