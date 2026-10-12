# 5. Hide styles paint the wallpaper

Status: accepted (2026-10-12)

## Context

Besides blurring, users want to hide everything except the focus: either showing the desktop, or showing it blurred.

## Decision

Add a **Focus Style** setting: `Blur` (default), `Hide (show desktop)` and `Hide (blur desktop)`. The hide styles make the Overlay opaque and draw the screen's wallpaper in it (sharp, or under a within-window blur). Nothing is done to other apps.

The wallpaper comes from `NSWorkspace.desktopImageURL(for:)` with the screen's scaling options. Wallpaper apps (such as Unsplash Wallpapers) store the picture in their sandbox container, which macOS blocks other apps from reading (`kTCCServiceSystemPolicyAppData`). In that case Focus Up captures the `WindowManager` "Wallpaper" window with ScreenCaptureKit. It needs Screen Recording permission, requested only when a hide style is chosen. Captures refresh every 10 minutes.

## Alternatives

- **Hide other apps (`NSRunningApplication.hide()`)**: shows the true desktop, but changes app state, needs restoring on exit, and can't hide the Focused App's other windows in window scope. Rejected.

## Consequences

- Hide styles work in both scopes and crossfade like blur.
- Desktop icons and widgets aren't shown, and dynamic or aerial wallpapers show as a still frame refreshed every 10 minutes.
- Without Screen Recording, a container-stored wallpaper shows only as the desktop fill colour.
