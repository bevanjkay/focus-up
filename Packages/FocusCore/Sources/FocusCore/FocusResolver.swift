public struct FocusRules: Equatable, Sendable {
    public var ignoredBundleIDs: Set<String>
    public var utilityAppsNeverTakeFocus: Bool

    public init(ignoredBundleIDs: Set<String> = [], utilityAppsNeverTakeFocus: Bool = false) {
        self.ignoredBundleIDs = ignoredBundleIDs
        self.utilityAppsNeverTakeFocus = utilityAppsNeverTakeFocus
    }

    func canTakeFocus(_ app: AppInfo, ownPID: Int32) -> Bool {
        if app.pid == ownPID { return false }
        if let bundleID = app.bundleID, ignoredBundleIDs.contains(bundleID) { return false }
        return !(utilityAppsNeverTakeFocus && app.isUtility)
    }
}

public enum FocusResolver {
    /// The Focused App after `activated` becomes frontmost: Focus Up itself and Ignored Apps keep the previous focus.
    public static func focusedApp(
        afterActivating activated: AppInfo, previous: AppInfo?, ownPID: Int32, rules: FocusRules
    ) -> AppInfo? {
        rules.canTakeFocus(activated, ownPID: ownPID) ? activated : previous
    }

    /// The Focused App when Focus Mode turns on. `candidates` are the frontmost app, then window owners front to back.
    public static func initialFocus(candidates: [AppInfo], ownPID: Int32, rules: FocusRules) -> AppInfo? {
        candidates.first { rules.canTakeFocus($0, ownPID: ownPID) }
    }
}
