import AppKit

/// Draws a `Wallpaper` the way the desktop lays it out.
final class WallpaperView: NSView {
    var wallpaper: Wallpaper? {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setFillColor(wallpaper?.fillColour ?? NSColor.black.cgColor)
        context.fill(bounds)
        guard let wallpaper, let image = wallpaper.image else { return }
        context.interpolationQuality = .high
        context.draw(image, in: Self.imageRect(for: image, gravity: wallpaper.gravity, in: bounds))
    }

    private static func imageRect(for image: CGImage, gravity: CALayerContentsGravity, in bounds: CGRect) -> CGRect {
        let size = CGSize(width: image.width, height: image.height)
        guard size.width > 0, size.height > 0 else { return bounds }
        let widthRatio = bounds.width / size.width
        let heightRatio = bounds.height / size.height
        let scale: CGFloat
        switch gravity {
        case .resize: return bounds
        case .center: return centred(CGSize(width: size.width / 2, height: size.height / 2), in: bounds)
        case .resizeAspect: scale = min(widthRatio, heightRatio)
        default: scale = max(widthRatio, heightRatio)
        }
        return centred(CGSize(width: size.width * scale, height: size.height * scale), in: bounds)
    }

    private static func centred(_ size: CGSize, in bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
    }
}
