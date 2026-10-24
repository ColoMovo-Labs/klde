# Workspace layout model

This is a mock and backend contract. It does not claim control of the host
compositor.

## Modes

| Mode | User-facing meaning | First KWin mapping |
| --- | --- | --- |
| Floating | windows keep independent geometry | compositor default geometry |
| Classic Tiling | visible split/master-stack arrangement | KWin tile tree and public script APIs |
| Scrolling Tiling | focus-following horizontal columns | KLDE planner; map only supported geometry/tile requests |
| Mixed | tiled policy with selected floating windows | per-window tile/floating state and app rules |

The names are KLDE product language. They do not expose Hyprland or niri as
runtime modes and do not imply copied code or branding.

## Workspace state

A workspace stores a stable ID, order, output association, preferred mode,
strategy, gap policy, border policy, orientation, default ratio and active state.
A window stores a stable opaque ID, application ID, workspace/output IDs, effective
floating state, optional logical geometry and confirmation state. Application rules
are ordered by explicit window override, application rule, workspace policy, then
backend default.

Remembered geometry is logical and output-aware. On reconnect or output loss,
KLDE clamps it to a usable area and never reapplies it without reconciling the
current compositor state.

## KWin strategy

The first real adapter probes the KWin engine family and capabilities. Classic
Tiling may use `Workspace.rootTile`, `TileManager` and tile management operations
where the target KWin profile exposes them. Mixed mode uses per-window tile/floating
state. Scrolling Tiling remains a KLDE-owned planner: it computes columns and
focus movement, then asks the adapter for supported geometry or tile operations.
A KWin profile may report Scrolling Tiling unavailable without changing the shell's
model.

All requests are asynchronous. The backend emits accepted/pending state, then
confirmed or rejected state from compositor events. QML never receives native
KWin handles and never calls KWin scripts directly.

## Mock layout lab

The future Window Layout Lab will show fake application surfaces in all four modes,
with focus, gaps, transition and workspace metadata. It is a visual contract test;
it is not evidence that host windows are tiled. Real acceptance requires a KWin
adapter running against an identified engine build under a nested or dedicated
Wayland session.
