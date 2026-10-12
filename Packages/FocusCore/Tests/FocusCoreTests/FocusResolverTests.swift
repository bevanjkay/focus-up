import Testing

@testable import FocusCore

struct FocusResolverTests {
    let safari = app(10, "com.apple.Safari")
    let notes = app(11, "com.apple.Notes")
    let raycast = app(12, "com.raycast.macos", utility: true)
    let focusUp = app(ownPID, "me.bevankay.FocusUp", utility: true)

    @Test func activatedAppTakesFocus() {
        let result = FocusResolver.focusedApp(afterActivating: notes, previous: safari, ownPID: ownPID, rules: .init())
        #expect(result == notes)
    }

    @Test func focusUpItselfNeverTakesFocus() {
        let result = FocusResolver.focusedApp(
            afterActivating: focusUp, previous: safari, ownPID: ownPID, rules: .init())
        #expect(result == safari)
    }

    @Test func ignoredAppKeepsPreviousFocus() {
        let rules = FocusRules(ignoredBundleIDs: ["com.apple.Notes"])
        let result = FocusResolver.focusedApp(afterActivating: notes, previous: safari, ownPID: ownPID, rules: rules)
        #expect(result == safari)
    }

    @Test func ignoredAppWithNoPreviousFocusLeavesNothingFocused() {
        let rules = FocusRules(ignoredBundleIDs: ["com.apple.Notes"])
        let result = FocusResolver.focusedApp(afterActivating: notes, previous: nil, ownPID: ownPID, rules: rules)
        #expect(result == nil)
    }

    @Test func utilityAppTakesFocusWhenRuleIsOff() {
        let result = FocusResolver.focusedApp(
            afterActivating: raycast, previous: safari, ownPID: ownPID, rules: .init())
        #expect(result == raycast)
    }

    @Test func utilityAppKeepsPreviousFocusWhenRuleIsOn() {
        let rules = FocusRules(utilityAppsNeverTakeFocus: true)
        let result = FocusResolver.focusedApp(afterActivating: raycast, previous: safari, ownPID: ownPID, rules: rules)
        #expect(result == safari)
    }

    @Test func initialFocusSkipsAppsThatCannotTakeFocus() {
        let rules = FocusRules(ignoredBundleIDs: ["com.apple.Safari"])
        let result = FocusResolver.initialFocus(candidates: [focusUp, safari, notes], ownPID: ownPID, rules: rules)
        #expect(result == notes)
    }

    @Test func initialFocusIsNilWithoutCandidates() {
        #expect(FocusResolver.initialFocus(candidates: [focusUp], ownPID: ownPID, rules: .init()) == nil)
    }
}
