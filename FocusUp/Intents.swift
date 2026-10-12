import AppIntents
import FocusCore

enum ScopeOption: String, AppEnum {
    case app
    case window

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Focus Scope"
    static let caseDisplayRepresentations: [ScopeOption: DisplayRepresentation] = [
        .app: "App", .window: "Window",
    ]

    var scope: FocusScope { FocusScope(rawValue: rawValue) ?? .app }
}

enum StyleOption: String, AppEnum {
    case blur
    case hide
    case hideBlurred

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Focus Style"
    static let caseDisplayRepresentations: [StyleOption: DisplayRepresentation] = [
        .blur: "Blur", .hide: "Hide (show desktop)", .hideBlurred: "Hide (blur desktop)",
    ]

    var style: FocusStyle { FocusStyle(rawValue: rawValue) ?? .blur }
}

struct ToggleFocusModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Focus Mode"
    static let description = IntentDescription("Turns Focus Mode on or off, whichever it isn't.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        FocusController.shared.toggle()
        return .result(value: FocusController.shared.isEnabled)
    }
}

struct SetFocusModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Focus Mode"
    static let description = IntentDescription("Turns Focus Mode on or off.")

    @Parameter(title: "On", default: true)
    var isOn: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Turn Focus Mode \(\.$isOn)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        FocusController.shared.isEnabled = isOn
        return .result()
    }
}

struct SetFocusScopeIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Focus Scope"
    static let description = IntentDescription("Keeps either the whole focused app or only its focused window sharp.")

    @Parameter(title: "Scope", default: .app)
    var scope: ScopeOption

    static var parameterSummary: some ParameterSummary {
        Summary("Set Focus Scope to \(\.$scope)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        FocusController.shared.scope = scope.scope
        return .result()
    }
}

struct SetFocusStyleIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Focus Style"
    static let description = IntentDescription("Blurs or hides everything outside the focus.")

    @Parameter(title: "Style", default: .blur)
    var style: StyleOption

    static var parameterSummary: some ParameterSummary {
        Summary("Set Focus Style to \(\.$style)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        FocusController.shared.style = style.style
        return .result()
    }
}

/// Lets a system Focus (such as Work) drive Focus Mode. When the Focus ends, the system performs this again with
/// default values, which turns Focus Mode off and restores any settings the Focus overrode.
struct FocusUpFocusFilter: SetFocusFilterIntent {
    static let title: LocalizedStringResource = "Set Focus Up"
    static let description = IntentDescription("Turns on Focus Mode while this Focus is on.")

    @Parameter(title: "Turn Focus Mode On", default: false)
    var isOn: Bool

    @Parameter(title: "Scope")
    var scope: ScopeOption?

    @Parameter(title: "Style")
    var style: StyleOption?

    @Parameter(title: "Intensity", controlStyle: .slider, inclusiveRange: (0, 1))
    var intensity: Double?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: isOn ? "Focus Mode on" : "Focus Mode off")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        FocusController.shared.applyFocusFilter(
            FocusFilterSettings(isOn: isOn, scope: scope?.scope, style: style?.style, intensity: intensity))
        return .result()
    }
}

struct FocusUpShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleFocusModeIntent(),
            phrases: ["Toggle \(.applicationName)", "Toggle Focus Mode in \(.applicationName)"],
            shortTitle: "Toggle Focus Mode", systemImageName: "circle.dashed.inset.filled")
    }
}
