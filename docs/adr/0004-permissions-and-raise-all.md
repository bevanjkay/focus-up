# 4. Permission strategy and Raise-all

Status: accepted (2026-10-12)

## Context

Clicking one window of an app raises only that window. The app's other windows can stay interleaved below other apps' windows, and the Overlay would blur them. Window scope needs to know the key window and when it changes, which only Accessibility provides.

## Decision

- **App scope (default)** needs no permissions. When the Focused App changes, Raise-all brings all its windows forward with `NSRunningApplication.activate(options: .activateAllWindows)`. The Overlay is then ordered below its lowest window.
- **Window scope** is opt-in. Request Accessibility only when the user switches to it, explaining why and deep-linking to System Settings. Fall back to app scope until permission is granted. Track the key window with `AXObserver` (`kAXFocusedWindowChangedNotification`).

## Consequences

- Most users never see a permission prompt.
- Raise-all was verified on macOS 27 in the [M0 spikes](../../spikes/M0/README.md). Called from a background accessory app on an already-active app, it fixes interleaving and keeps the clicked window on top. The fallback isn't needed.
