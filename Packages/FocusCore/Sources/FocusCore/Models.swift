import CoreGraphics

/// An app as Focus Up sees it.
public struct AppInfo: Equatable, Sendable {
    public let pid: Int32
    public let bundleID: String?
    /// The app has no Dock icon (an accessory or `LSUIElement` app).
    public let isUtility: Bool

    public init(pid: Int32, bundleID: String?, isUtility: Bool) {
        self.pid = pid
        self.bundleID = bundleID
        self.isUtility = isUtility
    }
}

/// An on-screen window, with `frame` in CoreGraphics global coordinates (top-left origin of the primary display).
public struct WindowInfo: Equatable, Sendable {
    public let number: Int
    public let pid: Int32
    public let frame: CGRect
    public let layer: Int
    public let alpha: Double

    public init(number: Int, pid: Int32, frame: CGRect, layer: Int, alpha: Double) {
        self.number = number
        self.pid = pid
        self.frame = frame
        self.layer = layer
        self.alpha = alpha
    }
}

/// A display, with `frame` in CoreGraphics global coordinates.
public struct Display: Equatable, Sendable {
    public let id: UInt32
    public let frame: CGRect

    public init(id: UInt32, frame: CGRect) {
        self.id = id
        self.frame = frame
    }
}

/// What stays sharp: the Focused App, narrowed to its Focused Window when `windowFrame` is set (window scope).
public struct FocusTarget: Equatable, Sendable {
    public let pid: Int32
    public let windowFrame: CGRect?

    public init(pid: Int32, windowFrame: CGRect? = nil) {
        self.pid = pid
        self.windowFrame = windowFrame
    }
}

public enum FocusScope: String, CaseIterable, Codable, Sendable {
    case app
    case window
}
