# Manual QA checklist

Run before each release, on macOS 27. Each item should pass in both app scope and window scope unless noted.

## Core
- [ ] Toggle Focus Mode from the menu, `⌃⌥⌘F` and a recorded custom hotkey.
- [ ] Switching apps with ⌘-Tab, the Dock and a click moves the blur within about 200 ms, with no flash of unblurred content.
- [ ] App scope: an app with windows interleaved behind other apps has all its windows sharp after activation (Raise-all).
- [ ] App scope: switching between windows of the Focused App doesn't fade the blur.
- [ ] Clicking a blurred area focuses the window underneath.
- [ ] Finder with only the desktop focused, or an app with all windows minimised, hides the Overlay.
- [ ] Reduce Motion on gives instant transitions.
- [ ] Focus Mode state is restored after quitting and relaunching.

## Displays, Spaces, Stage Manager
- [ ] Two or more displays: other apps are blurred on every display, and the Focused App is sharp wherever it is.
- [ ] Plugging in or removing a display and changing the arrangement or resolution adjusts the Overlays correctly.
- [ ] Switching Spaces keeps the Overlay present and correct.
- [ ] A full-screen Focused App shows no Overlay; leaving full-screen restores it.
- [ ] Stage Manager: the side strip is blurred, and switching stages behaves.

## Focus Style
- [ ] Hide (show desktop) covers every other window with the wallpaper, with the right scaling on each display.
- [ ] Hide (blur desktop) shows the wallpaper blurred and dimmed.
- [ ] A wallpaper from a system folder or Pictures shows without Screen Recording permission.
- [ ] A wallpaper from a wallpaper app (such as Unsplash) prompts for Screen Recording, then shows correctly.
- [ ] Changing the wallpaper while a hide style is on updates within a refresh.

## Settings and lists
- [ ] Focus Up's Settings window is never blurred and previews Intensity changes live.
- [ ] An Ignored App activating leaves the previous Focused App in focus.
- [ ] Utility app rule off: launchers (such as Raycast) hide the Overlay while open. Rule on: the blur stays put.
- [ ] Pinned App Cut-outs follow drags and resizes and disappear when the pinned window closes.
- [ ] Picture in Picture and other floating windows stay sharp.
- [ ] Launch at login works after enabling it from first run or Settings.

## Permissions (window scope)
- [ ] Switching to window scope without Accessibility shows the explanation and deep link, and stays in app scope.
- [ ] Granting permission switches to window scope without a relaunch.
- [ ] Revoking permission while running falls back to app scope gracefully.
- [ ] Sheets, pop-overs and floating panels of the Focused Window stay sharp.

## Shortcuts and Focus
- [ ] Toggle, Turn On, Turn Off and Set Focus Scope intents work from Shortcuts.
- [ ] A Focus filter on a system Focus (such as Work) switches Focus Mode and applies its scope and Intensity.

## Distribution
- [ ] The downloaded release passes Gatekeeper (notarised and stapled).
- [ ] Sparkle detects and installs an update from the previous release.
