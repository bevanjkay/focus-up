import AppKit
import FocusCore

/// Owns the Overlay for one display. On a focus change the new Overlay appears at once with the previously
/// sharp area left open, and a second panel fades in over just that area, so the rest of the display never
/// changes and the newly sharp area is never covered. Re-anchoring within the same focus (switching between
/// windows of the Focused App) re-orders in place without a fade.
@MainActor
final class OverlayController {
    static let fadeDuration: TimeInterval = 0.35

    private var current: OverlayPanel
    private var spare: OverlayPanel
    private var cutouts: [CGRect] = []
    private var sharpRects: [CGRect] = []
    /// The previously sharp area still being faded in by `spare`, kept open in `current` until it finishes.
    private var revealing: [CGRect] = []
    private var revealID = 0

    init(frame: NSRect) {
        current = OverlayPanel(frame: frame)
        spare = OverlayPanel(frame: frame)
    }

    func apply(
        _ plan: OverlayPlan, frame: NSRect, cutouts: [CGRect], sharpRects: [CGRect] = [],
        appearance: OverlayAppearance, style: FocusStyle, wallpaper: Wallpaper?, animated: Bool,
        crossfade: Bool = true
    ) {
        let duration = animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? Self.fadeDuration : 0
        let previouslySharp = self.sharpRects
        self.cutouts = cutouts
        self.sharpRects = sharpRects
        guard plan.isVisible, let anchor = plan.orderBelowWindow else {
            revealing = []
            fadeOut(current, duration: duration)
            fadeOut(spare, duration: duration)
            return
        }
        if current.isVisible, current.orderedBelowWindow == anchor || !crossfade {
            current.configure(
                frame: frame, appearance: appearance, cutouts: cutouts + revealing, style: style,
                wallpaper: wallpaper)
            current.order(below: anchor)
            if current.alphaValue < 1 { fade(current, to: 1, duration: duration) }
            return
        }
        let outgoing = current
        swap(&current, &spare)
        guard outgoing.isVisible, duration > 0 else {
            revealing = []
            current.configure(
                frame: frame, appearance: appearance, cutouts: cutouts, style: style, wallpaper: wallpaper)
            current.alphaValue = 0
            current.order(below: anchor)
            fade(current, to: 1, duration: duration)
            fadeOut(outgoing, duration: duration)
            return
        }
        revealing = previouslySharp
        revealID += 1
        let id = revealID
        current.configure(
            frame: frame, appearance: appearance, cutouts: cutouts + revealing, style: style, wallpaper: wallpaper)
        fade(current, to: 1, duration: 0)
        current.order(below: anchor)

        let reveal = outgoing
        fade(reveal, to: 0, duration: 0)
        reveal.configure(
            frame: frame, appearance: appearance, cutouts: cutouts, revealing: revealing, style: style,
            wallpaper: wallpaper)
        reveal.order(below: anchor)
        fade(reveal, to: 1, duration: duration) { [weak self, weak reveal] in
            guard let self, let reveal, revealID == id else { return }
            revealing = []
            current.setCoverage(cutouts: self.cutouts)
            reveal.remove()
        }
    }

    func tearDown() {
        current.remove()
        spare.remove()
    }

    private func fadeOut(_ panel: OverlayPanel, duration: TimeInterval) {
        guard panel.isVisible else { return }
        fade(panel, to: 0, duration: duration) { [weak panel] in
            guard let panel, panel.alphaValue == 0 else { return }
            panel.remove()
        }
    }

    private func fade(
        _ panel: NSPanel, to alpha: CGFloat, duration: TimeInterval, completion: (@MainActor () -> Void)? = nil
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = alpha
        } completionHandler: {
            MainActor.assumeIsolated { completion?() }
        }
    }
}
