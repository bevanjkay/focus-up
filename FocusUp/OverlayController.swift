import AppKit
import FocusCore

/// Owns the Overlay for one display. On a focus change a fresh Overlay appears at once with the previously
/// sharp area left open, and a reveal panel fades in over just that area, so the rest of the display never
/// changes and the newly sharp area is never covered. Re-anchoring within the same focus (switching between
/// windows of the Focused App) re-orders in place without a fade.
///
/// Panels are only reshaped while off screen: changing a visible panel's blur mask drops the blur for a frame.
@MainActor
final class OverlayController {
    static let fadeDuration: TimeInterval = 0.35

    private var panels: [OverlayPanel]
    private var current: OverlayPanel
    /// Covers the area that was sharp before the last focus change, until the next one.
    private var reveal: OverlayPanel?
    private var revealing: [CGRect] = []
    private var sharpRects: [CGRect] = []

    init(frame: NSRect) {
        current = OverlayPanel(frame: frame)
        panels = [current]
    }

    func apply(
        _ plan: OverlayPlan, frame: NSRect, cutouts: [CGRect], sharpRects: [CGRect] = [],
        appearance: OverlayAppearance, style: FocusStyle, wallpaper: Wallpaper?, animated: Bool,
        crossfade: Bool = true
    ) {
        let duration = animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? Self.fadeDuration : 0
        let previouslySharp = self.sharpRects
        self.sharpRects = sharpRects
        guard plan.isVisible, let anchor = plan.orderBelowWindow else {
            fadeOut(current, duration: duration)
            if let reveal { fadeOut(reveal, duration: duration) }
            reveal = nil
            revealing = []
            return
        }
        if current.isVisible, current.orderedBelowWindow == anchor || !crossfade {
            current.configure(
                frame: frame, appearance: appearance, cutouts: cutouts + revealing, style: style,
                wallpaper: wallpaper)
            current.order(below: anchor)
            if current.alphaValue < 1 { fade(current, to: 1, duration: duration) }
            if let reveal {
                reveal.configure(
                    frame: frame, appearance: appearance, cutouts: cutouts, revealing: revealing, style: style,
                    wallpaper: wallpaper)
                reveal.order(below: anchor)
            }
            return
        }
        let outgoing = [current, reveal].compactMap(\.self).filter(\.isVisible)
        current = hiddenPanel(frame: frame)
        reveal = nil
        guard !outgoing.isEmpty, duration > 0 else {
            revealing = []
            current.configure(
                frame: frame, appearance: appearance, cutouts: cutouts, style: style, wallpaper: wallpaper)
            current.alphaValue = 0
            current.order(below: anchor)
            fade(current, to: 1, duration: duration)
            for panel in outgoing { fadeOut(panel, duration: duration) }
            return
        }
        revealing = previouslySharp
        current.configure(
            frame: frame, appearance: appearance, cutouts: cutouts + revealing, style: style, wallpaper: wallpaper)
        current.alphaValue = 1
        current.order(below: anchor)

        let reveal = hiddenPanel(frame: frame)
        reveal.configure(
            frame: frame, appearance: appearance, cutouts: cutouts, revealing: revealing, style: style,
            wallpaper: wallpaper)
        reveal.alphaValue = 0
        reveal.order(below: anchor)
        self.reveal = reveal
        for panel in outgoing {
            fade(panel, to: 0, duration: 0)
            panel.remove()
        }
        fade(reveal, to: 1, duration: duration)
    }

    func tearDown() {
        for panel in panels { panel.remove() }
    }

    private func hiddenPanel(frame: NSRect) -> OverlayPanel {
        if let panel = panels.first(where: { !$0.isVisible && $0 !== current && $0 !== reveal }) { return panel }
        let panel = OverlayPanel(frame: frame)
        panels.append(panel)
        return panel
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
