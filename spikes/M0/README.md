# M0 spikes

Throwaway checks on macOS 27.0 (26A428) with Xcode 27.0, on a two-display setup (3440×1440 external plus a built-in Retina display). Run on 2026-10-12.

`Spike.swift` is a single-file harness. It runs helper processes that show striped test windows, plus an overlay process. Window order is read from `CGWindowListCopyWindowInfo`, and the blur is checked with `screencapture`.

```sh
swiftc -O spikes/M0/Spike.swift -o /tmp/FocusUpSpike
```

The binary must be named `FocusUpSpike`, because `stack` filters on that owner name.

## Results

| # | Question | Result |
| --- | --- | --- |
| 1 | Does `NSVisualEffectView` (`.behindWindow`) in our window blur other processes' windows? | ✅ Yes. Other apps' windows and the desktop behind the overlay are blurred; windows above it stay sharp. |
| 2 | Can `order(.below, relativeTo:)` target another process's window number? | ✅ Yes. The overlay landed directly below the requested window every time, including when re-ordered later. |
| 3 | Does Raise-all work from a background accessory app? | ✅ Yes. Clicking one window of a background app raised only that window (stack `A1 > B1 > A2`). `NSRunningApplication.activate(options: .activateAllWindows)` then gave `A1 > A2 > B1`, keeping the clicked window on top. `yieldActivation` + `activate(from:options:)` and `AXRaise` also worked; neither is needed. |
| 4a | Full-screen | ✅ With `[.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]` the overlay is absent from full-screen Spaces, with nothing blurred. Leaving full-screen restores it. No full-screen detection code is needed for the full-screen display. |
| 4b | Stage Manager | ⏳ Not run. Enabling it rearranges every window on the machine, so it's left as a manual check. |

## Notes for later milestones

- A full-screen window brings an extra untitled, same-owner window at layer 0 on its Space. `OverlayPlanner` should ignore untitled windows matching the screen frame when choosing what to order below.
- Untested: ordering an overlay on one display relative to a Focused App window that sits on a full-screen Space on another display. Check in M4.
