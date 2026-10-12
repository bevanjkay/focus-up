import CoreGraphics

@testable import FocusCore

let ownPID: Int32 = 1

func app(_ pid: Int32, _ bundleID: String, utility: Bool = false) -> AppInfo {
    AppInfo(pid: pid, bundleID: bundleID, isUtility: utility)
}

func window(_ number: Int, pid: Int32, _ frame: CGRect, layer: Int = 0, alpha: Double = 1) -> WindowInfo {
    WindowInfo(number: number, pid: pid, frame: frame, layer: layer, alpha: alpha)
}

let mainDisplay = Display(id: 1, frame: CGRect(x: 0, y: 0, width: 3440, height: 1440))
let laptopDisplay = Display(id: 2, frame: CGRect(x: 3440, y: 145, width: 1728, height: 1117))
