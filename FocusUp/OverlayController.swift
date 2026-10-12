import AppKit
import FocusCore

/// Owns the Overlay for one display. Focus changes crossfade between two panels, so the newly blurred
/// area fades in while the newly sharp area is never covered. Re-anchoring within the same focus (switching
/// between windows of the Focused App) re-orders in place without a fade.
@MainActor
final class OverlayController {
    static let fadeDuration: TimeInterval = 0.2

    private var current: OverlayPanel
    private var spare: OverlayPanel

    init(frame: NSRect) {
        current = OverlayPanel(frame: frame)
        spare = OverlayPanel(frame: frame)
    }

    func apply(
        _ plan: OverlayPlan, frame: NSRect, cutouts: [CGRect], appearance: OverlayAppearance, style: FocusStyle,
        wallpaper: Wallpaper?, animated: Bool, crossfade: Bool = true
    ) {
        let duration = animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? Self.fadeDuration : 0
        guard plan.isVisible, let anchor = plan.orderBelowWindow else {
            fadeOut(current, duration: duration)
            return
        }
        if current.isVisible, current.orderedBelowWindow == anchor || !crossfade {
            current.configure(
                frame: frame, appearance: appearance, cutouts: cutouts, style: style, wallpaper: wallpaper)
            current.order(below: anchor)
            if current.alphaValue < 1 { fade(current, to: 1, duration: duration) }
            return
        }
        let outgoing = current
        swap(&current, &spare)
        current.configure(
            frame: frame, appearance: appearance, cutouts: cutouts, style: style, wallpaper: wallpaper)
        current.alphaValue = 0
        current.order(below: anchor)
        fade(current, to: 1, duration: duration)
        fadeOut(outgoing, duration: duration)
    }

    func tearDown() {
        current.remove()
        spare.remove()
    }

    private func fadeOut(_ panel: OverlayPanel, duration: TimeInterval) {
        guard panel.isVisible else { return }
        fade(panel, to: 0, duration: duration) { [weak self, weak panel] in
            guard let panel, panel !== self?.current || panel.alphaValue == 0 else { return }
            panel.remove()
        }
    }

    private func fade(
        _ panel: NSPanel, to alpha: CGFloat, duration: TimeInterval, completion: (@MainActor () -> Void)? = nil
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            panel.animator().alphaValue = alpha
        } completionHandler: {
            MainActor.assumeIsolated { completion?() }
        }
    }
}
