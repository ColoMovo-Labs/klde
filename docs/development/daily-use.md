# owoDE daily-use milestone

Ubuntu remains the primary supported distribution. Fedora 44 is the current
runtime bring-up target, with niri protected as the owner's host compositor.
KWin is the compositor foundation; Plasma Shell is not a runtime requirement.
All builds, tests, static analysis and packages are produced in CircleCI/CNB.
Do not replace the host session or install privileged helpers during bring-up.

## Current gap, not a release claim

The preview has working cloud packages, bilingual UI and native surface source,
but most system and window state is still mock. A separate native popup host
and rounded input regions now replace hidden-preview popup ownership and
full-window pointer interception in the source. Exact-commit KWin evidence is
still required before accepting them. Native input regions, exclusive zones, maximized clients and
multi-output behavior still need protocol evidence and real interaction tests.
This is not yet a desktop suitable for ordinary daily use.

## Acceptance order

| Gate | Required evidence |
| --- | --- |
| Native session foundation | KWin + LayerShellQt roles; wallpaper below clients; ribbon/Dock anchored; only visible controls intercept input; usable popups and keyboard focus; correct maximization; graceful isolated shutdown |
| Real application workflow | XDG discovery and locale-aware names; standards-compliant launching; KWin active window/workspace state; running indicators derived from real windows; launcher keyboard and global shortcut behavior |
| Basic system controls | NetworkManager, PipeWire/WirePlumber, UPower, brightness, Bluetooth capabilities; event-driven confirmed state and permission/error handling; absent services degrade clearly |
| Session essentials | Notifications, portals, polkit agent, input methods, persistence, output/hotplug, suspend/resume; no duplicate daemons; safe logout; independently reviewed real Wayland locking |
| Daily-use release | Clean Ubuntu/Fedora install/update/remove; login entry only after nested acceptance; recovery path; accessibility; documented supported versions; actual owner-host session evidence |

Mock providers and Visual Lab remain explicit, selectable development paths.
Mock state must never appear as confirmed live state. A passing software/GPU
correctness job is not a hardware performance or security certification.

## Initial Lingmo application migration

Start with [Calculator](../../apps/calculator/README.md): a pinned Qt 6 engine
adaptation in an independent process, original notices and corresponding source,
owoDE palette/controls, bilingual UI, arithmetic tests, screenshots and packages
on both distributions. Audit file manager/editor next; do not migrate their
platform/theme plugins, desktop/session daemons or security components blindly.
No wholesale Lingmo fork, compositor fork or advanced tiling is needed here.
