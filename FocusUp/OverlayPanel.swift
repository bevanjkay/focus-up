import AppKit
import FocusCore

/// A borderless, click-through panel that blurs or hides (behind the wallpaper) and dims everything below it,
/// except for Cut-outs. While revealing, it covers only the given rects.
///
/// The hide styles clip the whole content rather than the wallpaper: a within-window blur samples whatever is
/// painted behind it, so a wallpaper clipped to the covered area would fade out along every edge of it.
final class OverlayPanel: NSPanel {
    private let wallpaperView = WallpaperView()
    private let contentMask = CAShapeLayer()
    private let effectView = NSVisualEffectView()
    private let dimView = NSView()
    private let dimMask = CAShapeLayer()
    private(set) var orderedBelowWindow: Int?
    private var overlayAppearance: OverlayAppearance?
    private var cutouts: [CGRect]?
    private var revealing: [CGRect]?
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

        wallpaperView.autoresizingMask = [.width, .height]
        contentMask.fillRule = .evenOdd
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
        container.wantsLayer = true
        for view in [wallpaperView, effectView, dimView] {
            view.frame = container.bounds
            container.addSubview(view)
        }
        contentView = container
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func configure(
        frame: NSRect, appearance: OverlayAppearance, cutouts: [CGRect], revealing: [CGRect]? = nil,
        style: FocusStyle, wallpaper: Wallpaper?
    ) {
        if self.frame != frame {
            setFrame(frame, display: false)
            self.cutouts = nil
        }
        if appearance != overlayAppearance {
            dimView.alphaValue = appearance.dimOpacity
            overlayAppearance = appearance
        }
        if style != self.style || wallpaper != self.wallpaper {
            if style.hidesWindows != self.style?.hidesWindows { self.cutouts = nil }
            setStyle(style, wallpaper: wallpaper)
            self.style = style
            self.wallpaper = wallpaper
        }
        setCoverage(cutouts: cutouts, revealing: revealing, clipsContent: style.hidesWindows)
    }

    private func setCoverage(cutouts: [CGRect], revealing: [CGRect]?, clipsContent: Bool) {
        guard cutouts != self.cutouts || revealing != self.revealing else { return }
        let bounds = NSRect(origin: .zero, size: frame.size)
        let covered = revealing.map(Self.union) ?? CGPath(rect: bounds, transform: nil)
        let path = covered.subtracting(Self.union(cutouts))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for mask in [dimMask, contentMask] { mask.frame = bounds }
        dimMask.path = path
        contentMask.path = Self.spanning(path, bounds: bounds)
        contentView?.layer?.mask = clipsContent ? contentMask : nil
        CATransaction.commit()
        let isFullyCovered = cutouts.isEmpty && revealing == nil
        effectView.maskImage =
            clipsContent || isFullyCovered ? nil : Self.maskImage(size: frame.size, path: path)
        self.cutouts = cutouts
        self.revealing = revealing
    }

    func order(below windowNumber: Int) {
        order(.below, relativeTo: windowNumber)
        orderedBelowWindow = windowNumber
    }

    func remove() {
        orderOut(nil)
        orderedBelowWindow = nil
    }

    private func setStyle(_ style: FocusStyle, wallpaper: Wallpaper?) {
        wallpaperView.isHidden = !style.hidesWindows
        effectView.isHidden = style == .hide
        // Behind-window blur samples other apps' windows; within-window blur samples the painted wallpaper.
        effectView.blendingMode = style == .blur ? .behindWindow : .withinWindow
        wallpaperView.wallpaper = wallpaper
    }

    /// Core Animation only renders the part of a masked layer its mask covers, so the blur of a panel covering a
    /// small area would find nothing to sample beyond it. A point in two opposite corners keeps it all rendered.
    private static func spanning(_ path: CGPath, bounds: CGRect) -> CGPath {
        let corner = CGSize(width: 1, height: 1)
        let corners = [
            CGRect(origin: bounds.origin, size: corner),
            CGRect(origin: CGPoint(x: bounds.maxX - 1, y: bounds.maxY - 1), size: corner),
        ]
        return path.union(union(corners))
    }

    private static func union(_ rects: [CGRect]) -> CGPath {
        rects.reduce(CGMutablePath() as CGPath) { $0.union(CGPath(rect: $1, transform: nil)) }
    }

    private static func maskImage(size: NSSize, path: CGPath) -> NSImage {
        NSImage(size: size, flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.addPath(path)
            context.setFillColor(.black)
            context.fillPath()
            return true
        }
    }
}
