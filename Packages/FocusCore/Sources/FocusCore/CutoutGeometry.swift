import CoreGraphics

public enum CutoutGeometry {
    /// Clips global CoreGraphics `frames` to `display` and converts them to display-local AppKit coordinates
    /// (bottom-left origin), dropping any that fall outside it.
    public static func localRects(for frames: [CGRect], in display: CGRect) -> [CGRect] {
        frames.compactMap { frame in
            let visible = frame.intersection(display)
            guard !visible.isNull, !visible.isEmpty else { return nil }
            return CGRect(
                x: visible.minX - display.minX, y: display.maxY - visible.maxY,
                width: visible.width, height: visible.height)
        }
    }
}
