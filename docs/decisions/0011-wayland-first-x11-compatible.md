# 0011 — Wayland first, X11 compatible

## Context

Wayland is the future session target; legacy apps and driver/input issues still need compatibility.

## Decision

Use Qt QPA for common UI, Wayland for the future default, and retain tested XCB compatibility.

## Consequences

Separate native capabilities and honest session support from ordinary-window smoke tests.

## Alternatives considered

Wayland-only loses early compatibility; X11-first makes future integration harder.

## Future review conditions

Review before removing X11 or selecting a default compositor.
