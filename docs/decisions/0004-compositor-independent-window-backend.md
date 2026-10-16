# ADR 0004: Compositor-independent window backend

Status: accepted direction; implementation deferred until used.

## Context

The shell needs both floating and tiled workflows with workspace-level defaults
and per-window exceptions. The final compositor is not selected.

## Decision

Introduce a capability-based WindowManagerBackend in Phase 1 with mock state.
Separate shell-surface hosting from management of other applications. Keep native
handles private and distinguish accepted requests from confirmed state.

## Consequences

The standalone window demonstrates interaction without controlling the host.
Adapters may support different capabilities. Persistent application rules,
remembered geometry and scrolling tiling require later design and tests.

## Alternatives considered

Binding QML directly to KWin or wlroots-specific protocols would entangle UI and
platform behavior. A new compositor is premature. One global tiling/floating mode
would not meet the workspace philosophy.
