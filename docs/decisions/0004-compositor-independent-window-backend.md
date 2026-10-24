# ADR 0004: Compositor-independent window backend

Status: accepted direction; implementation deferred until used.

## Context

The shell needs both floating and tiled workflows with workspace-level defaults
and per-window exceptions. The final engine profile is not selected, but KWin is
the first integration candidate because KLDE and LingmoOS share a KWin-family
foundation.

## Decision

Introduce a capability-based WindowManagerBackend in Phase 1 with mock state.
Separate shell-surface hosting from management of other applications. Keep native
handles private and distinguish accepted requests from confirmed state. Implement
the first real adapter as a KWin profile probe; distinguish upstream KWin 6 from
the deepin/Lingmo KWin lineage and never assume plugin ABI compatibility.

## Consequences

The standalone window demonstrates interaction without controlling the host.
Adapters may support different capabilities. Classic Tiling can first use KWin's
public tile/script APIs; Scrolling Tiling remains KLDE-owned planning mapped to
supported operations. Persistent application rules, remembered geometry and
secure session locking require later design and tests.

## Alternatives considered

Binding QML directly to KWin or wlroots-specific protocols would entangle UI and
platform behavior. A new compositor is premature and remains a fallback only if
the KWin adapter proves a concrete blocker. One global tiling/floating mode would
not meet the workspace philosophy.
