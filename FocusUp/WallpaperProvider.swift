import AppKit
import ImageIO
import OSLog
import Observation
import ScreenCaptureKit

private let logger = Logger(subsystem: "me.bevankay.FocusUp", category: "Wallpaper")

/// Supplies each screen's wallpaper for the hide styles. Reading the desktop picture file needs no permission, but
/// files inside another app's container (wallpaper apps) are blocked by macOS, so those fall back to capturing the
/// desktop picture window with ScreenCaptureKit, which needs Screen Recording permission.
@MainActor
@Observable
final class WallpaperProvider {
    /// Captures are refreshed so dynamic wallpapers stay roughly current.
    private static let captureLifetime: Duration = .seconds(600)
    /// Refreshes can run at 15 Hz while windows are pinned; looking the wallpaper up that often is wasteful.
    private static let lookupLifetime: Duration = .seconds(2)

    private(set) var needsScreenCapturePermission = false

    @ObservationIgnored var onUpdate: () -> Void = {}
    @ObservationIgnored private var files: [URL: CGImage?] = [:]
    @ObservationIgnored private var captures: [UInt32: (url: URL, image: CGImage, time: ContinuousClock.Instant)] = [:]
    @ObservationIgnored private var capturesInFlight: Set<UInt32> = []
    @ObservationIgnored private var recent: [UInt32: (wallpaper: Wallpaper, time: ContinuousClock.Instant)] = [:]

    func wallpaper(for screen: NSScreen) -> Wallpaper {
        if let recent = recent[screen.displayID], ContinuousClock.now - recent.time < Self.lookupLifetime {
            return recent.wallpaper
        }
        let wallpaper = lookUpWallpaper(for: screen)
        recent[screen.displayID] = (wallpaper, .now)
        return wallpaper
    }

    private func lookUpWallpaper(for screen: NSScreen) -> Wallpaper {
        let workspace = NSWorkspace.shared
        let options = workspace.desktopImageOptions(for: screen) ?? [:]
        let fillColour = (options[.fillColor] as? NSColor)?.cgColor ?? NSColor.black.cgColor
        guard let url = workspace.desktopImageURL(for: screen) else {
            return Wallpaper(image: nil, gravity: .resizeAspectFill, fillColour: fillColour)
        }
        if let image = file(at: url, screen: screen) {
            return Wallpaper(image: image, gravity: Self.gravity(for: options), fillColour: fillColour)
        }
        return Wallpaper(image: capture(of: screen, url: url), gravity: .resize, fillColour: fillColour)
    }

    func requestScreenCapturePermission() {
        if !CGRequestScreenCaptureAccess(),
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        {
            NSWorkspace.shared.open(url)
        }
    }

    private func file(at url: URL, screen: NSScreen) -> CGImage? {
        if let cached = files[url] { return cached }
        let maxPixels = max(screen.frame.width, screen.frame.height) * screen.backingScaleFactor
        let image = Self.decode(url, maxPixels: maxPixels)
        if image == nil { logger.info("Desktop picture isn't readable, falling back to capture: \(url.path)") }
        if files.count >= 8 { files.removeAll() }
        files[url] = image
        return image
    }

    private func capture(of screen: NSScreen, url: URL) -> CGImage? {
        let displayID = screen.displayID
        let cached = captures[displayID].flatMap { $0.url == url ? $0 : nil }
        guard CGPreflightScreenCaptureAccess() else {
            needsScreenCapturePermission = true
            return nil
        }
        needsScreenCapturePermission = false
        let isStale = cached.map { ContinuousClock.now - $0.time > Self.captureLifetime } ?? true
        if isStale, capturesInFlight.insert(displayID).inserted {
            let size = CGSize(
                width: screen.frame.width * screen.backingScaleFactor,
                height: screen.frame.height * screen.backingScaleFactor)
            Task {
                let image = await Self.captureWallpaperWindow(displayID: displayID, pixelSize: size)
                capturesInFlight.remove(displayID)
                guard let image else { return }
                captures[displayID] = (url, image, .now)
                recent[displayID] = nil
                onUpdate()
            }
        }
        return cached?.image
    }

    private nonisolated static func captureWallpaperWindow(displayID: UInt32, pixelSize: CGSize) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else { return nil }
            let wallpapers = content.windows.filter {
                $0.owningApplication?.bundleIdentifier == "com.apple.WindowManager"
                    && $0.windowLayer < Int(CGWindowLevelForKey(.desktopIconWindow)) && $0.frame == display.frame
            }
            guard !wallpapers.isEmpty else { return nil }
            let configuration = SCStreamConfiguration()
            configuration.width = Int(pixelSize.width)
            configuration.height = Int(pixelSize.height)
            configuration.showsCursor = false
            let filter = SCContentFilter(display: display, including: wallpapers)
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        } catch {
            logger.error("Wallpaper capture failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func decode(_ url: URL, maxPixels: CGFloat) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func gravity(for options: [NSWorkspace.DesktopImageOptionKey: Any]) -> CALayerContentsGravity {
        let scaling = (options[.imageScaling] as? NSNumber).flatMap { NSImageScaling(rawValue: $0.uintValue) }
        let allowsClipping = (options[.allowClipping] as? NSNumber)?.boolValue ?? true
        switch scaling {
        case .scaleAxesIndependently: return .resize
        case .scaleNone: return .center
        case .scaleProportionallyDown: return .resizeAspect
        default: return allowsClipping ? .resizeAspectFill : .resizeAspect
        }
    }
}
