# Focus Up — Plan

Focus Up is a native macOS menu-bar app that keeps one app (or window) in focus by blurring everything else. Terms are defined in [CONTEXT.md](CONTEXT.md), and key decisions are in [docs/adr](docs/adr).

## Product decisions

| Area | Decision |
| --- | --- |
| Identity | "Focus Up", `me.bevankay.FocusUp`, MIT, open source at `bevanjkay/focus-up` |
| Platform | macOS 27 only |
| Form | Menu-bar only (`LSUIElement`), with a SwiftUI `MenuBarExtra` and a Settings window |
| Distribution | GitHub Releases, signed with Developer ID and notarised; updates through Sparkle. No App Store. |
| Focus Scope | App by default with Raise-all; window scope optional (needs Accessibility) |
| Effect | Public API material blur plus dim; one Intensity slider (dim; blur stays fully opaque) |
| Focus Style | Blur (default), Hide (show desktop) or Hide (blur desktop): the hide styles paint the wallpaper over other windows ([ADR 5](docs/adr/0005-hide-styles-paint-the-wallpaper.md)) |
| Displays | One Overlay per display; Focused App sharp wherever it is |
| Spaces | Overlay joins all Spaces; hidden when the Focused App is full-screen; Stage Manager strip blurred |
| Clicks | Overlay is click-through; clicking a blurred window focuses it |
| Nothing to keep sharp | Overlay hides |
| Transitions | Fade of about 350 ms over only the newly blurred area; instant with Reduce Motion |
| Lists | Ignored Apps and Pinned Apps start empty; Utility app rule is a setting, off by default |
| Own windows | Focus Up's windows float above the Overlay and are never blurred; Settings previews live |
| Activation | Menu toggle; global hotkey `⌃⌥⌘F` (recordable); App Intents; Focus filter |
| Focus Sessions | 15/25/45/60 min presets or a custom length; a countdown in the menu bar; +5 min and End; when it finishes, Focus Mode returns to its prior state and a notification appears |
| Defaults | Restore the last Focus Mode state; launch at login off, offered on first run |
| Localisation | String Catalog with US English as the base; docs in Australian English |

## Architecture

```
FocusUp.xcodeproj
├── FocusUp (app target)        AppKit/SwiftUI glue, system integration
└── Packages/FocusCore          pure Swift, unit-tested, no AppKit
```

### FocusCore (local Swift package)

Pure logic driven by value types and protocols, so all of it is testable with fakes.

- `WindowSnapshot`: window number, PID, bundle ID, frame, layer, on-screen flag, display.
- `FocusSettings`: scope, Intensity, Ignored and Pinned bundle IDs, Utility app rule.
- `FocusResolver`: (activation event, previous focus, settings, app metadata) → new `FocusTarget` or "keep previous". Applies Ignored Apps and the Utility app rule.
- `OverlayPlanner`: (`FocusTarget`, window snapshots, displays) → per-display `OverlayPlan` with visibility, the window number to order below, Cut-out rects and whether Raise-all is needed. Covers "nothing to keep sharp". Full-screen Spaces are handled by the system (see the M0 spikes).
- `CutoutGeometry`: converts pinned window frames into per-display mask rects (flips coordinates between CG and AppKit).
- Protocols the app implements: `WindowListProviding`, `ActivationSource`, `FocusedWindowSource`.

### FocusUp app target

- `FocusController` (`@Observable`, `@MainActor`): owns the state and wires sources into FocusCore, then applies plans.
- `ActivationMonitor`: `NSWorkspace.didActivateApplicationNotification`, plus Space, display and wake notifications.
- `WindowListProvider`: wraps `CGWindowListCopyWindowInfo` (on-screen, excluding desktop elements).
- `PinnedWindowPoller`: polls at about 15 Hz only while a Pinned App has a visible window.
- `AXFocusMonitor`: window scope only; `AXObserver` on the Focused App for focused-window changes.
- `OverlayWindowController`: one per `NSScreen`. Borderless `NSPanel` at normal level, `ignoresMouseEvents = true`, collection behaviour `[.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]`. Content is an `NSVisualEffectView` (`.behindWindow`) plus a dim layer and a `CAShapeLayer` mask for Cut-outs. Ordered with `order(.below, relativeTo:)`, with fades through `NSAnimationContext` that respect Reduce Motion.
- `Raiser`: `NSRunningApplication.activate(options: .activateAllWindows)`.
- UI:
  - `MenuBarExtra`: toggle, scope, Intensity, Settings and Quit.
  - Settings window at `.floating` level, with tabs for General, Apps (Ignored/Pinned pickers) and Shortcuts.
  - One-screen first-run welcome.
- Integrations:
  - KeyboardShortcuts (global hotkey).
  - Sparkle (updates).
  - `SMAppService.mainApp` (launch at login).
  - App Intents: `ToggleFocusModeIntent`, `SetFocusModeIntent`, `SetFocusScopeIntent`, `FocusUpFocusFilter: SetFocusFilterIntent`.
- Persistence: `UserDefaults` (`@AppStorage`), with apps stored by bundle ID.

### Focus change flow

1. An activation, Space change or AX focused-window event arrives.
2. `FocusResolver` decides the new target, or keeps the previous one.
3. In app scope with a new target, `Raiser` raises all its windows.
4. A window snapshot is taken, and `OverlayPlanner` produces the per-display plans.
5. Each `OverlayWindowController` applies its plan: fade in or out, reorder, update the mask.

## Milestones

Each milestone ends with its tests green and the relevant `docs/qa.md` items checked.

0. **Spikes (de-risk on macOS 27)**: four throwaway checks, each confirming or revising its ADR:
   - Behind-window blur of other apps' windows.
   - Cross-process `order(.below, relativeTo:)`.
   - Raise-all under cooperative activation.
   - Overlay behaviour with Stage Manager and full-screen.
1. **Project skeleton**:
   - Xcode project, `FocusCore` package and String Catalog.
   - `swift format` config (bundled with Xcode, so CI needs no extra installs).
   - GitHub Actions `checks.yml` running build and test on PRs.
   - README and LICENSE.
2. **FocusCore, test first**: `FocusResolver`, `OverlayPlanner` and `CutoutGeometry`, with fakes for every case in the decision table.
3. **App scope MVP**: menu bar toggle, hotkey, single display, Raise-all, fades, nothing-to-keep-sharp, and restore state.
4. **Displays and Spaces**: an Overlay per screen, screen-change handling, all Spaces, full-screen, Stage Manager.
5. **Settings**:
   - Intensity with live preview.
   - Ignored Apps and the Utility app rule.
   - Pinned Apps with Cut-outs and the poller.
   - Launch at login and first-run welcome.
6. **Window scope**: Accessibility request flow, `AXFocusMonitor`, sheet and panel handling, and revocation fallback.
7. **Shortcuts and Focus**: App Intents and the Focus filter.
8. **Distribution**:
   - Sparkle with an EdDSA key held in repo secrets.
   - Tag-triggered `release.yml`: archive, sign with Developer ID, `notarytool` submit, staple, DMG/zip, GitHub Release, appcast update.
   - First public release `v0.1.0`.

## Risks

- ~~**Cross-process ordering or behind-window blur behaves differently on macOS 27.**~~ Both verified in M0.
- ~~**Cooperative activation refuses Raise-all.**~~ Verified working in M0.
- **Stage Manager ordering surprises.** Full-screen was verified in M0. Stage Manager is still a manual check (covered in the QA checklist).
- **Cut-out lag on fast drags.** Accepted; tune the poll rate if it's noticeable.
- **GPU and battery cost of full-screen behind-window blur on several displays.** Measure in M4 with Instruments, and hide Overlays on displays that have nothing to blur.
