// M0 spike harness. Throwaway code: see spikes/M0/README.md for the findings.
//
//   FocusUpSpike target --name A --windows 2 --x 250 --y 250
//   FocusUpSpike send --name A --cmd front:0|activate|fullscreen:0|close:0|quit
//   FocusUpSpike overlay --below <windowNumber> --x --y --w --h [--duration 30]
//   FocusUpSpike raise --pid <pid> --method activate|yield|ax
//   FocusUpSpike click --x <x> --y <y>
//   FocusUpSpike stack
//
// Coordinates are CoreGraphics global (top-left origin of the primary display).

import AppKit
import ApplicationServices

let args = CommandLine.arguments
func arg(_ name: String) -> String? {
    guard let i = args.firstIndex(of: "--\(name)"), i + 1 < args.count else { return nil }
    return args[i + 1]
}
func double(_ name: String, _ fallback: Double) -> Double { arg(name).flatMap(Double.init) ?? fallback }

let notificationName = Notification.Name("me.bevankay.FocusUp.spike")
let centre = DistributedNotificationCenter.default()

func appKitRect(x: Double, y: Double, w: Double, h: Double) -> NSRect {
    let primaryHeight = NSScreen.screens[0].frame.height
    return NSRect(x: x, y: primaryHeight - y - h, width: w, height: h)
}

func printStack(_ label: String) {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    let spikeWindows = list.filter {
        ($0[kCGWindowLayer as String] as? Int) == 0 && ($0[kCGWindowOwnerName as String] as? String) == "FocusUpSpike"
    }
    let names = spikeWindows.map { "\($0[kCGWindowName as String] as? String ?? "?")#\($0[kCGWindowNumber as String] ?? "?")" }
    let front = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
    print("[\(label)] front pid \(front): \(names.joined(separator: " > "))")
}

final class StripeView: NSView {
    let colour: NSColor
    let label: String
    init(frame: NSRect, colour: NSColor, label: String) {
        self.colour = colour
        self.label = label
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        colour.setFill()
        bounds.fill()
        NSColor.white.setFill()
        for x in stride(from: 0.0, to: bounds.width, by: 24) {
            NSRect(x: x, y: 0, width: 6, height: bounds.height).fill()
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 72), .foregroundColor: NSColor.black,
        ]
        label.draw(at: NSPoint(x: 30, y: 30), withAttributes: attributes)
    }
}

let app = NSApplication.shared
var keepAlive: [AnyObject] = []

switch args.dropFirst().first {
case "target":
    let name = arg("name") ?? "A"
    let count = Int(arg("windows") ?? "1") ?? 1
    let x = double("x", 250), y = double("y", 250)
    let colour: NSColor = name == "A" ? .systemRed : .systemBlue
    app.setActivationPolicy(.regular)
    var windows: [NSWindow] = []
    for i in 0..<count {
        let frame = appKitRect(x: x + Double(i) * 400, y: y + Double(i) * 200, w: 600, h: 400)
        let window = NSWindow(contentRect: frame, styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.title = "\(name)\(i + 1)"
        window.isReleasedWhenClosed = false
        window.collectionBehavior = .fullScreenPrimary
        window.contentView = StripeView(frame: frame, colour: colour, label: window.title)
        window.orderFrontRegardless()
        windows.append(window)
        print("\(window.title) \(window.windowNumber)")
    }
    print("pid \(ProcessInfo.processInfo.processIdentifier)")
    fflush(stdout)
    keepAlive.append(centre.addObserver(forName: notificationName, object: name, queue: .main) { note in
        let parts = (note.userInfo?["cmd"] as? String ?? "").split(separator: ":")
        let index = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        switch parts.first {
        case "front": windows[index].orderFrontRegardless()
        case "activate": NSApp.activate()
        case "fullscreen": windows[index].toggleFullScreen(nil)
        case "close": windows[index].orderOut(nil)
        case "quit": NSApp.terminate(nil)
        default: break
        }
    })
    app.run()

case "send":
    centre.postNotificationName(
        notificationName, object: arg("name") ?? "A", userInfo: ["cmd": arg("cmd") ?? ""], deliverImmediately: true)
    usleep(300_000)

case "overlay":
    app.setActivationPolicy(.accessory)
    let frame = appKitRect(x: double("x", 200), y: double("y", 200), w: double("w", 1300), h: double("h", 800))
    let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    panel.title = "Overlay"
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.hidesOnDeactivate = false
    panel.level = .normal
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
    let blur = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
    blur.blendingMode = .behindWindow
    blur.material = .fullScreenUI
    blur.state = .active
    let dim = NSView(frame: blur.bounds)
    dim.wantsLayer = true
    dim.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
    blur.addSubview(dim)
    panel.contentView = blur
    if let below = arg("below").flatMap(Int.init) {
        panel.order(.below, relativeTo: below)
    } else {
        panel.orderFrontRegardless()
    }
    print("Overlay \(panel.windowNumber)")
    fflush(stdout)
    keepAlive.append(panel)
    keepAlive.append(centre.addObserver(forName: notificationName, object: "Overlay", queue: .main) { note in
        let parts = (note.userInfo?["cmd"] as? String ?? "").split(separator: ":")
        if parts.first == "below", parts.count > 1, let number = Int(parts[1]) {
            panel.order(.below, relativeTo: number)
        } else if parts.first == "quit" {
            NSApp.terminate(nil)
        }
    })
    DispatchQueue.main.asyncAfter(deadline: .now() + double("duration", 30)) { NSApp.terminate(nil) }
    app.run()

case "raise":
    guard let pid = arg("pid").flatMap(Int32.init), let target = NSRunningApplication(processIdentifier: pid) else {
        print("no such pid")
        exit(1)
    }
    printStack("before")
    switch arg("method") ?? "activate" {
    case "activate":
        print("activate(options:) ->", target.activate(options: [.activateAllWindows]))
    case "yield":
        app.yieldActivation(to: target)
        print("activate(from:options:) ->", target.activate(from: .current, options: [.activateAllWindows]))
    case "ax":
        let element = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value)
        let windows = value as? [AXUIElement] ?? []
        for window in windows.reversed() { AXUIElementPerformAction(window, kAXRaiseAction as CFString) }
        print("AXRaise on \(windows.count) windows")
    default:
        break
    }
    usleep(500_000)
    printStack("after")

case "click":
    let point = CGPoint(x: double("x", 0), y: double("y", 0))
    for type in [CGEventType.leftMouseDown, .leftMouseUp] {
        CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
        usleep(50_000)
    }
    usleep(500_000)
    printStack("after click")

case "stack":
    printStack(arg("label") ?? "stack")

default:
    print("usage: see header comment")
}
