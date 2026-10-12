# 3. Pinned Apps via Cut-outs

Status: accepted (2026-10-12)

## Context

Pinned Apps must stay sharp while another app is focused. Raising their windows above the Overlay would need Accessibility permission and would fight the user's own window order.

## Decision

Mask Cut-outs into the Overlay over each visible Pinned App window. Track their frames by polling `CGWindowListCopyWindowInfo` at about 15 Hz, only while a Pinned App has a visible window. Otherwise Focus Up polls at 2 Hz while Focus Mode is on. No notification without Accessibility covers the Focused App closing its last window or the stack shifting under the Overlay.

## Consequences

- No permission is needed, and polling drops back to 2 Hz when nothing is pinned.
- Any window overlapping a pinned window's frame also shows through. This is accepted as rare for typical pins (calls, music mini-players).
- Cut-outs can lag a frame or so behind fast drags.
