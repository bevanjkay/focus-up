import AppKit
import FocusCore
import KeyboardShortcuts
import Observation

/// Tracks the Focused App and keeps one Overlay per display ordered directly below it.
@MainActor
@Observable
final class FocusController {
    static let shared = FocusController()

    private enum Key {
        static let isEnabled = "focusModeEnabled"
        static let intensity = "intensity"
        static let style = "focusStyle"
        static let ignoredApps = "ignoredBundleIDs"
        static let pinnedApps = "pinnedBundleIDs"
        static let utilityApps = "utilityAppsNeverTakeFocus"
    }

    private static let pollInterval: TimeInterval = 0.5
    /// Faster polling so Cut-outs follow pinned windows as they move.
    private static let pinnedPollInterval: TimeInterval = 1.0 / 15
    /// Raise-all is asynchronous, so re-plan once the raised windows have settled.
    private static let raiseSettleDelay: Duration = .milliseconds(150)

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            defaults.set(isEnabled, forKey: Key.isEnabled)
            isEnabled ? start() : stop()
        }
    }

    var intensity: Double {
        didSet {
            defaults.set(intensity, forKey: Key.intensity)
            refresh(force: true)
        }
    }

    var style: FocusStyle {
        didSet {
            defaults.set(style.rawValue, forKey: Key.style)
            refresh(force: true)
            if style.hidesWindows { checkWallpaperAccess(requestingPermission: true) }
        }
    }

    var ignoredBundleIDs: Set<String> {
        didSet { defaults.set(Array(ignoredBundleIDs).sorted(), forKey: Key.ignoredApps) }
    }

    var pinnedBundleIDs: Set<String> {
        didSet {
            defaults.set(Array(pinnedBundleIDs).sorted(), forKey: Key.pinnedApps)
            refresh(force: true)
        }
    }

    var utilityAppsNeverTakeFocus: Bool {
        didSet { defaults.set(utilityAppsNeverTakeFocus, forKey: Key.utilityApps) }
    }

    let wallpapers = WallpaperProvider()

    private(set) var focusedApp: AppInfo?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var overlays: [UInt32: OverlayController] = [:]
    @ObservationIgnored private var lastPlan: OverlayPlan?
    @ObservationIgnored private var lastPlannedPID: Int32?
    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    var rules: FocusRules {
        FocusRules(ignoredBundleIDs: ignoredBundleIDs, utilityAppsNeverTakeFocus: utilityAppsNeverTakeFocus)
    }

    private var pinnedPIDs: Set<Int32> {
        guard !pinnedBundleIDs.isEmpty else { return [] }
        return Set(
            NSWorkspace.shared.runningApplications
                .filter { $0.bundleIdentifier.map(pinnedBundleIDs.contains) ?? false }
                .map(\.processIdentifier))
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Key.isEnabled)
        intensity = defaults.object(forKey: Key.intensity) as? Double ?? OverlayAppearance.defaultIntensity
        style = defaults.string(forKey: Key.style).flatMap(FocusStyle.init) ?? .blur
        ignoredBundleIDs = Set(defaults.stringArray(forKey: Key.ignoredApps) ?? [])
        pinnedBundleIDs = Set(defaults.stringArray(forKey: Key.pinnedApps) ?? [])
        utilityAppsNeverTakeFocus = defaults.bool(forKey: Key.utilityApps)
        wallpapers.onUpdate = { [weak self] in self?.refresh(force: true) }
        if style.hidesWindows { checkWallpaperAccess(requestingPermission: false) }
        KeyboardShortcuts.onKeyUp(for: .toggleFocusMode) { [weak self] in self?.isEnabled.toggle() }
        if isEnabled { start() }
    }

    func toggle() { isEnabled.toggle() }

    /// Works out whether the hide styles need Screen Recording, even while Focus Mode is off and nothing is drawn.
    private func checkWallpaperAccess(requestingPermission: Bool) {
        for screen in NSScreen.screens { _ = wallpapers.wallpaper(for: screen) }
        if requestingPermission, wallpapers.needsScreenCapturePermission {
            wallpapers.requestScreenCapturePermission()
        }
    }

    // MARK: - Lifecycle

    private func start() {
        focusedApp = initialFocus()
        raiseIfNeeded()
        observe()
        refresh(force: true)
    }

    private func stop() {
        schedulePolling(interval: nil)
        for (centre, token) in observers { centre.removeObserver(token) }
        observers = []
        lastPlan = nil
        lastPlannedPID = nil
        for overlay in overlays.values {
            overlay.apply(
                .hidden, frame: .zero, cutouts: [], appearance: appearance, style: style, wallpaper: nil,
                animated: true)
        }
    }

    private func observe() {
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.didActivateApplicationNotification) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.activated(SystemState.app(app))
        }
        observe(workspace, NSWorkspace.activeSpaceDidChangeNotification) { [weak self] _ in self?.refresh(force: true) }
        observe(workspace, NSWorkspace.didWakeNotification) { [weak self] _ in self?.refresh(force: true) }
        observe(NotificationCenter.default, NSApplication.didChangeScreenParametersNotification) { [weak self] _ in
            self?.rebuildOverlays()
        }
    }

    private func observe(
        _ centre: NotificationCenter, _ name: Notification.Name, handler: @escaping @MainActor (Notification) -> Void
    ) {
        let token = centre.addObserver(forName: name, object: nil, queue: .main) { note in
            nonisolated(unsafe) let note = note
            MainActor.assumeIsolated { handler(note) }
        }
        observers.append((centre, token))
    }

    // MARK: - Focus

    private func activated(_ app: AppInfo) {
        let resolved = FocusResolver.focusedApp(
            afterActivating: app, previous: focusedApp, ownPID: SystemState.ownPID, rules: rules)
        guard resolved != focusedApp else { return }
        focusedApp = resolved
        raiseIfNeeded()
        refresh()
    }

    private func initialFocus() -> AppInfo? {
        var candidates: [AppInfo] = NSWorkspace.shared.frontmostApplication.map { [SystemState.app($0)] } ?? []
        var seen = Set(candidates.map(\.pid))
        for window in SystemState.windows() where window.layer == 0 && seen.insert(window.pid).inserted {
            if let app = SystemState.app(pid: window.pid) { candidates.append(app) }
        }
        return FocusResolver.initialFocus(candidates: candidates, ownPID: SystemState.ownPID, rules: rules)
    }

    private func raiseIfNeeded() {
        guard let focusedApp,
            OverlayPlanner.needsRaiseAll(
                pid: focusedApp.pid, windows: SystemState.windows(), ownPID: SystemState.ownPID),
            let runningApp = NSRunningApplication(processIdentifier: focusedApp.pid)
        else { return }
        runningApp.activate(options: [.activateAllWindows])
        Task { [weak self] in
            try? await Task.sleep(for: Self.raiseSettleDelay)
            self?.refresh()
        }
    }

    // MARK: - Overlays

    private var appearance: OverlayAppearance { OverlayAppearance(intensity: intensity) }

    private func rebuildOverlays() {
        for overlay in overlays.values { overlay.tearDown() }
        overlays = [:]
        refresh(force: true)
    }

    private func refresh(force: Bool = false) {
        guard isEnabled else { return }
        let screens = NSScreen.screens
        let plan = OverlayPlanner.plan(
            target: focusedApp.map { FocusTarget(pid: $0.pid) }, windows: SystemState.windows(),
            displays: screens.map(\.display), pinnedPIDs: pinnedPIDs, ownPID: SystemState.ownPID)
        // Re-apply even when the plan is unchanged: the anchor window may have moved in the stack (after
        // Raise-all, for example), and re-ordering an Overlay that is already in place is a no-op.
        let animated = !force && lastPlan != nil && plan != lastPlan
        let crossfade = focusedApp?.pid != lastPlannedPID
        lastPlan = plan
        lastPlannedPID = focusedApp?.pid

        for screen in screens {
            let overlay = overlays[screen.displayID] ?? OverlayController(frame: screen.frame)
            overlays[screen.displayID] = overlay
            overlay.apply(
                plan, frame: screen.frame, cutouts: plan.cutouts[screen.displayID] ?? [], appearance: appearance,
                style: style, wallpaper: style.hidesWindows ? wallpapers.wallpaper(for: screen) : nil,
                animated: animated, crossfade: crossfade)
        }
        schedulePolling(interval: plan.cutouts.isEmpty ? Self.pollInterval : Self.pinnedPollInterval)
        let connected = Set(screens.map(\.displayID))
        for (id, overlay) in overlays where !connected.contains(id) {
            overlay.tearDown()
            overlays[id] = nil
        }
    }

    private func schedulePolling(interval: TimeInterval?) {
        guard pollTimer?.timeInterval != interval || pollTimer?.isValid != true else { return }
        pollTimer?.invalidate()
        pollTimer = interval.map { interval in
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }
}
