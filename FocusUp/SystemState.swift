import AppKit
import FocusCore

/// Adapters from AppKit and CoreGraphics to FocusCore's value types.
enum SystemState {
    static let ownPID = ProcessInfo.processInfo.processIdentifier

    /// On-screen windows on the current Spaces, front to back.
    static func windows() -> [WindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        return list.compactMap { info in
            guard let number = info[kCGWindowNumber as String] as? Int,
                let pid = info[kCGWindowOwnerPID as String] as? Int32,
                let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary,
                let frame = CGRect(dictionaryRepresentation: boundsDictionary)
            else { return nil }
            return WindowInfo(
                number: number, pid: pid, frame: frame,
                layer: info[kCGWindowLayer as String] as? Int ?? 0,
                alpha: info[kCGWindowAlpha as String] as? Double ?? 1)
        }
    }

    static func app(_ runningApp: NSRunningApplication) -> AppInfo {
        AppInfo(
            pid: runningApp.processIdentifier, bundleID: runningApp.bundleIdentifier,
            isUtility: runningApp.activationPolicy != .regular)
    }

    static func app(pid: Int32) -> AppInfo? {
        NSRunningApplication(processIdentifier: pid).map(app)
    }
}

extension NSScreen {
    var displayID: UInt32 {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 ?? 0
    }

    /// The screen's frame in CoreGraphics global coordinates (top-left origin of the primary display).
    var globalFrame: CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.maxY ?? frame.maxY
        return CGRect(x: frame.minX, y: primaryHeight - frame.maxY, width: frame.width, height: frame.height)
    }

    var display: Display { Display(id: displayID, frame: globalFrame) }
}
