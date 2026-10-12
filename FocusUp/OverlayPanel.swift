import AppKit
import FocusCore

/// A borderless, click-through panel that blurs and dims everything below it, except for Cut-outs.
final class OverlayPanel: NSPanel {
    private let effectView = NSVisualEffectView()
    private let dimView = NSView()
    private let dimMask = CAShapeLayer()
    private(set) var orderedBelowWindow: Int?
    private var overlayAppearance: OverlayAppearance?
    private var cutouts: [CGRect]?

    init(frame: NSRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        title = "Focus Up Overlay"
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        level = .normal
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]

        effectView.blendingMode = .behindWindow
        effectView.material = .fullScreenUI
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        dimView.wantsLayer = true
        dimView.layer?.backgroundColor = NSColor.black.cgColor
        dimView.layer?.mask = dimMask
        dimMask.fillRule = .evenOdd
        dimView.autoresizingMask = [.width, .height]

        let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
        effectView.frame = container.bounds
        dimView.frame = container.bounds
        container.addSubview(effectView)
        container.addSubview(dimView)
        contentView = container
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func configure(frame: NSRect, appearance: OverlayAppearance, cutouts: [CGRect]) {
        if self.frame != frame {
            setFrame(frame, display: false)
            self.cutouts = nil
        }
        if appearance != overlayAppearance {
            dimView.alphaValue = appearance.dimOpacity
            overlayAppearance = appearance
        }
        if cutouts != self.cutouts {
            setCutouts(cutouts, size: frame.size)
            self.cutouts = cutouts
        }
    }

    func order(below windowNumber: Int) {
        order(.below, relativeTo: windowNumber)
        orderedBelowWindow = windowNumber
    }

    func remove() {
        orderOut(nil)
        orderedBelowWindow = nil
    }

    private func setCutouts(_ cutouts: [CGRect], size: NSSize) {
        let bounds = NSRect(origin: .zero, size: size)
        let path = CGMutablePath()
        path.addRect(bounds)
        for cutout in cutouts { path.addRect(cutout) }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dimMask.frame = bounds
        dimMask.path = path
        CATransaction.commit()
        effectView.maskImage = cutouts.isEmpty ? nil : Self.maskImage(size: size, holes: cutouts)
    }

    private static func maskImage(size: NSSize, holes: [CGRect]) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            rect.fill()
            for hole in holes { hole.fill(using: .clear) }
            return true
        }
    }
}
