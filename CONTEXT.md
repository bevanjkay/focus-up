# Focus Up — Glossary

Shared vocabulary for the code, docs and UI. Use these terms exactly; don't introduce synonyms.

| Term | Meaning |
| --- | --- |
| **Focus Mode** | The on/off state. When on, everything except the Focused App (or Focused Window) is blurred. |
| **Focused App** | The app that stays sharp in app scope. Normally the frontmost app, unless that app is an Ignored App. |
| **Focused Window** | The window that stays sharp in window scope: the app's key window plus its sheets, pop-overs and floating panels. |
| **Focus Scope** | Either `app` (default) or `window`. Window scope requires Accessibility permission. |
| **Overlay** | The borderless, click-through, blurred window Focus Up places on each display, ordered directly below the Focused App/Window. |
| **Focus Style** | How everything outside the focus is treated: `Blur` (default), `Hide (show desktop)` or `Hide (blur desktop)`. Hide styles paint the wallpaper over other windows. |
| **Intensity** | The single user-facing slider. Controls the Overlay's dim; the blur stays fully opaque and its radius is fixed by the system material. |
| **Raise-all** | Bringing every window of the Focused App forward when it gains focus, so app scope keeps all its windows sharp. |
| **Pinned App** | An app whose windows are never blurred, achieved with Cut-outs. |
| **Cut-out** | A hole masked out of the Overlay over a Pinned App's window frame. Anything overlapping that frame also shows through. |
| **Ignored App** | An app that never becomes the Focused App; when it activates, the previous Focused App stays in focus. The list starts empty. |
| **Utility app rule** | Optional setting (off by default): apps with no Dock icon (`LSUIElement`/accessory) are treated as Ignored Apps. |
| **Nothing to keep sharp** | The Focused App has no visible window on the current Space; the Overlay hides until a windowed app takes focus. |
