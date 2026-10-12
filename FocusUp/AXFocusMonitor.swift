import AppKit
import ApplicationServices

/// Watches one app's focused window through Accessibility. Only used in window scope.
@MainActor
final class AXFocusMonitor {
    static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    var onChange: () -> Void = {}
    private var observer: AXObserver?
    private var watchedPID: Int32?

    static var isTrusted: Bool { AXIsProcessTrusted() }

    private static var hasPrompted = false

    /// Shows the system prompt the first time; afterwards opens the Accessibility pane in System Settings.
    static func requestTrust() {
        guard !isTrusted else { return }
        if hasPrompted, let settingsURL {
            NSWorkspace.shared.open(settingsURL)
        } else {
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
            hasPrompted = true
        }
    }

    /// The focused window's frame in CoreGraphics global coordinates (top-left origin), which is what AX reports.
    static func focusedWindowFrame(pid: Int32) -> CGRect? {
        let app = AXUIElementCreateApplication(pid)
        var window: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &window) == .success,
            let window, CFGetTypeID(window) == AXUIElementGetTypeID()
        else { return nil }
        let element = window as! AXUIElement
        guard let origin: CGPoint = value(of: kAXPositionAttribute, in: element, type: .cgPoint),
            let size: CGSize = value(of: kAXSizeAttribute, in: element, type: .cgSize)
        else { return nil }
        return CGRect(origin: origin, size: size)
    }

    func watch(pid: Int32?) {
        guard pid != watchedPID else { return }
        stop()
        guard let pid, Self.isTrusted else { return }
        var observer: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else { return }
            let monitor = Unmanaged<AXFocusMonitor>.fromOpaque(refcon).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.onChange() }
        }
        guard AXObserverCreate(pid, callback, &observer) == .success, let observer else { return }
        let app = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        for notification in [kAXFocusedWindowChangedNotification, kAXMainWindowChangedNotification] {
            AXObserverAddNotification(observer, app, notification as CFString, refcon)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        self.observer = observer
        watchedPID = pid
    }

    func stop() {
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        observer = nil
        watchedPID = nil
    }

    private static func value<T>(of attribute: String, in element: AXUIElement, type: AXValueType) -> T? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success, let raw,
            CFGetTypeID(raw) == AXValueGetTypeID()
        else { return nil }
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        guard AXValueGetValue(raw as! AXValue, type, pointer) else { return nil }
        return pointer.pointee
    }
}
