# 2. Public API blur only

Status: accepted (2026-10-12)

## Context

Users want adjustable intensity. A true blur-radius control needs private API (`CABackdropLayer`/`CAFilter`). Focus Up is distributed outside the App Store, so notarisation wouldn't block it.

## Decision

Use only `NSVisualEffectView` materials. The blur stays fully opaque and the single Intensity slider controls the dim.

Intensity originally also lowered the blur's opacity. Live testing in M3 showed that even 85% opacity lets text and edges ghost through and reads as broken, so the blur never goes below full opacity.

## Consequences

- Stable across macOS updates, with nothing that can break at runtime.
- The range of the effect is narrower. If it feels too binary, revisit with a fallback-guarded private path in a new ADR.
