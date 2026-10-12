# 1. Blur with an ordered Overlay window, not screen capture

Status: accepted (2026-10-12)

## Context

Focus Up must blur every app except the Focused App. macOS gives no way to apply effects to another process's windows.

## Decision

Place one borderless, click-through Overlay window per display. It hosts an `NSVisualEffectView` with `.behindWindow` blending plus a dim layer. On every focus change, order it directly below the Focused App's (or Focused Window's) lowest window with `order(.below, relativeTo:)`, using window numbers from `CGWindowListCopyWindowInfo`.

The Overlay sits at normal window level. Floating windows (Picture in Picture, panels, notifications, menus, the Dock and the menu bar) therefore stay sharp.

## Alternatives

- **ScreenCaptureKit capture and blur**: heavier, adds latency, needs Screen Recording permission, and fights with the content it captures. Rejected.

## Consequences

- No permission is needed for app scope.
- The Focused App's windows must be contiguous at the top of the stack for app scope to look right. See Raise-all in [ADR 4](0004-permissions-and-raise-all.md).
- Cross-process `order(_:relativeTo:)` and behind-window blur of other apps were both verified on macOS 27 in the [M0 spikes](../../spikes/M0/README.md).
- With `.canJoinAllSpaces` and `.fullScreenNone`, the system keeps the Overlay off full-screen Spaces, so "hidden in full-screen" needs no detection code.
