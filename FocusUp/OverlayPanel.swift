import AppKit
import FocusCore

/// A borderless, click-through panel that blurs or hides (behind the wallpaper) and dims everything below it,
/// except for Cut-outs.
final class OverlayPanel: NSPanel {
    private let wallpaperView = WallpaperView()
    private let wallpaperMask = CAShapeLayer()
    private let effectView = NSVisualEffectView()
    private let dimView = NSView()
    private let dimMask = CAShapeLayer()
    private(set) var orderedBelowWindow: Int?
    private var overlayAppearance: OverlayAppearance?
    private var cutouts: [CGRect]?
    private var style: FocusStyle?
    private var wallpaper: Wallpaper?

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

        wallpaperView.wantsLayer = true
        wallpaperView.layer?.mask = wallpaperMask
        wallpaperView.autoresizingMask = [.width, .height]
        wallpaperMask.fillRule = .evenOdd
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
        for view in [wallpaperView, effectView, dimView] {
            view.frame = container.bounds
            container.addSubview(view)
        }
        contentView = container
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func configure(
        frame: NSRect, appearance: OverlayAppearance, cutouts: [CGRect], style: FocusStyle, wallpaper: Wallpaper?
    ) {
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
        if style != self.style || wallpaper != self.wallpaper {
            setStyle(style, wallpaper: wallpaper)
            self.style = style
            self.wallpaper = wallpaper
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
        for mask in [dimMask, wallpaperMask] {
            mask.frame = bounds
            mask.path = path
        }
        CATransaction.commit()
        effectView.maskImage = cutouts.isEmpty ? nil : Self.maskImage(size: size, holes: cutouts)
    }

    private func setStyle(_ style: FocusStyle, wallpaper: Wallpaper?) {
        wallpaperView.isHidden = !style.hidesWindows
        effectView.isHidden = style == .hide
        // Behind-window blur samples other apps' windows; within-window blur samples the painted wallpaper.
        effectView.blendingMode = style == .blur ? .behindWindow : .withinWindow
        wallpaperView.wallpaper = wallpaper
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
