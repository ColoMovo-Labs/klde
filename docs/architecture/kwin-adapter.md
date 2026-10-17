# KWin adapter and compatibility boundary

Status: architecture direction; no live KWin adapter is implemented in the
current mock shell.

KLDE and LingmoOS use KWin-family compositor foundations, so KWin is now the
first engine candidate for `WindowManagerBackend`. This does not make the KLDE
shell a Plasma shell or make every KWin-family build API-compatible. The adapter
must identify the engine family, API/build version, Qt/KF major versions and
Wayland protocol capabilities before exposing an operation.

## Engine families

The compatibility matrix must distinguish at least:

| Engine family | Meaning | KLDE policy |
| --- | --- | --- |
| `upstream-kwin6` | KDE KWin 6 with its public scripting/tile APIs | preferred first adapter target |
| `deepin-kwin-v25` | deepin-kwin lineage used by LingmoOS, based on a KWin 5.27 lineage with Qt 6/KF 6 work | separate probe and build target; never assume upstream KWin 6 ABI |
| `lingmo-kwin` | LingmoOS packaging/customization of the deepin lineage | compatible only through an explicit adapter profile |
| `unknown` | anything else | mock or read-only capability mode |

A version string alone is insufficient. Record Qt/KF major versions, KWin build
ID, supported script/QML API version, tile-tree support, window-rule support,
internal lock support, session-lock protocol support and geometry confirmation.

## Implementation order

1. **KWin Script/KPackage policy prototype.** Use the public scripting surface for
   workspace policy, application rules, focus, move/resize requests and a first
   Classic Tiling experiment. Keep the layout planner in KLDE-owned code and use
   opaque backend IDs in QML.
2. **KWin tile-tree integration.** On KWin 6, investigate `Workspace.rootTile`,
   `TileManager`, `Tile.manage`/`unmanage`/`resizeByPixels` and
   `Window.tileChanged`. These are capability-gated integration points for
   Classic Tiling and Mixed mode, not a replacement for KLDE's policy model.
3. **C++ effect or KDecoration3 plugin only when needed.** A visual effect,
   decoration or native blur bridge must be built in CI against the exact KWin
   headers and runtime. Binary effect ABI compatibility is not assumed across
   KWin releases.

Do not install LingmoOS or Cutefish `kwinrc` defaults, global shortcuts or theme
plugins into a KLDE session. Do not copy their branding or assume their private
KWin types are stable.

## Layout mapping

| KLDE mode | First KWin strategy | Boundary |
| --- | --- | --- |
| Floating | compositor default geometry | no layout planner required |
| Classic Tiling | KWin tile tree / split policy | preserve explicit floating exceptions |
| Scrolling Tiling | KLDE column planner, then supported KWin tile/geometry requests | KWin native tile tree is not assumed to scroll |
| Mixed | workspace policy plus per-window tile/floating state | dialogs and app rules may remain floating |

All requests are asynchronous in the real adapter: accepted requests expose a
pending ID, and confirmed geometry/layout arrives from compositor events. A
rejected or unsupported request must leave the previous effective state intact.

## Wayland and locking

The shell must never claim that a QML overlay is a secure lock screen. LingmoOS
and Cutefish lock-screen sources are PAM/X11 research references. A real KLDE
lock surface must use the KWin session integration available on the target
engine, or an explicitly detected Wayland session-lock protocol. The staging
`ext-session-lock-v1` protocol is a capability, not a universal KWin guarantee.
KWin's internal lock-screen support and the client protocol are separate probes.

## Sources

- [KWin scripting API](https://develop.kde.org/docs/plasma/kwin/api/)
- [KWin tile QML API](https://api.kde.org/qml-org-kde-kwin-tile.html)
- [KWin effects API](https://api.kde.org/kwin-effects.html)
- [Cutefish KWin plugin audit](https://github.com/cutefishos/kwin-plugins)
- [LingmoOS KWin fork](https://github.com/LingmoOS/lingmo-kwin)
- [Wayland session-lock protocol](https://wayland.app/protocols/ext-session-lock-v1)
