# KWin adapter and compatibility boundary

Status: the native/system-app shell now selects an event-driven KWin 6 scripting
adapter. Mock and Visual Lab retain their deterministic backend. Cloud acceptance
for this implementation is pending until the corresponding branch checks pass.

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


## First live adapter

`KWinWindowManagerBackend` probes the session bus owner and KWin support report,
then loads an original, temporary script into that exact unique bus owner. The
initial profiles are upstream 6.6 and 6.7; a successful live data handshake is
required before any capability is enabled. No effect/plugin ABI is linked.
Unknown versions and disconnected engines expose empty/unavailable state rather
than simulated workspaces. A lost owner clears all windows and running badges;
a replacement owner is reprobed with a fresh callback token and sequence.

The state script observes window creation/removal/activation, application
identity, minimized state, workspace membership and desktop changes. A one-shot
zero-delay timer coalesces events; there is no idle polling, cursor watcher,
geometry stream or continuous rendering. A single in-flight D-Bus report bounds
queued updates. Payload size/count/identity checks and monotonic sequences apply.
The callback accepts only the current KWin bus sender and instance token. This
protects this adapter's state channel, not an isolation boundary against code
already running as the same desktop user or inside KWin.

Workspace switching, window activation/unminimization, close requests and window
moves use short owned scripts with a fixed command vocabulary and JSON-encoded
IDs. User strings never become executable code. Calls are asynchronous, execute in a bounded FIFO, and expose `pendingRequests`
until the compositor acknowledges execution. An already-visible state does not
prove an outstanding request has completed. Confirmed state comes from compositor events; a close request still respects
application close handling. Scripts are unloaded only by their unique names,
including on teardown. No global `kwinrc`, shortcut or plugin is installed.
Layout algorithms, persistent rules, global shortcuts and arbitrary source
execution are not capabilities of this first adapter. Workspace layout is shown
as compositor-managed instead of labelling unknown state as Floating/Tiling.

Application matching gives the explicit desktop file identity precedence over
unique desktop-ID/StartupWMClass aliases. Ambiguous aliases remain unmatched.
Catalogued windows share a running/active group; uncatalogued normal windows get
an ephemeral Dock entry that disappears on close and cannot be pinned. No badge
is inferred from a launch PID. Catalog refresh preserves confirmed runtime state,
and a Dock activation targets a real existing window before requesting a launch.

## Reuse audit for this adapter

Inspected upstream KWin `workspace_wrapper.h`, `window.h`, `virtualdesktops.h`
and `scripting.cpp` on Plasma/6.7 (`d1f7073085cda18ff9eb6553c81cd7103ceaf462`),
and the Plasma/6.6 public profile (`b83db456e72c031dbe650316d6f5e6a7bb7ff57b`).
The public workspace/window API and asynchronous `callDBus` are the reusable
engine contracts. The new bridge and command scripts are authored for owoDE;
no upstream implementation code is embedded.

Lingmo KWin at `f8a56e12cfb5afa751e9cb521f01315f11859bfe` still declares a
5.27.3 project lineage with conditional Qt/KF major versions. Its scripting
workspace/engine files carry GPL-2.0-or-later notices. These implementations were
inspected, but are not asserted compatible with the upstream 6.6/6.7 adapter.
A Qt 6 build alone is not an API profile.

Cutefish plugins at `5df71a4e684682e33b5630b7831206d504158937` include a
windowAdded-based launcher script and KWin effects, KDecoration3 checks, and
session-specific `kwinrc`. The root license is GPLv3 and individual reused KDE
effect files retain GPL-2.0-or-later notices. Their launcher policy targets a
Cutefish ordinary-window overlay and custom window-class/title rules; owoDE's
existing layer-shell popup architecture does not need that policy. No Cutefish
script, configuration, decoration, artwork or branding is copied.

References:

- [Upstream KWin scripting API](https://develop.kde.org/docs/plasma/kwin/api/)
- [Audited upstream workspace interface](https://github.com/KDE/kwin/blob/d1f7073085cda18ff9eb6553c81cd7103ceaf462/src/scripting/workspace_wrapper.h)
- [Audited Lingmo scripting interface](https://github.com/LingmoOS/lingmo-kwin/blob/f8a56e12cfb5afa751e9cb521f01315f11859bfe/src/scripting/workspace_wrapper.h)
- [Audited Cutefish launcher policy](https://github.com/cutefishs/kwin-plugins/blob/5df71a4e684682e33b5630b7831206d504158937/scripts/cutefishlauncher/contents/code/main.js)

Acceptance must exercise real window addition/removal, multiple instances,
minimization/activation, workspace moves/switches, invalid requests and Dock
state on both distribution KWin builds. Owner restart and long-lived script
recovery, multi-output/per-output desktops, hardware/global input and production
reliability still need dedicated acceptance; the single-output test is not a
production-readiness claim.
