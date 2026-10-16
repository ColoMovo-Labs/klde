# Architecture

Status: initial design; only the minimal Qt window exists in Phase 0.

## Boundaries and process model

KLDE begins as one unprivileged Qt Quick process, `klde-shell`. This keeps
ownership, lifecycle and debugging understandable. QML renders presentation;
Qt-facing models and controllers expose state; C++ backend adapters translate
requests to system services or the host compositor. Separate services are added
only when privilege separation, fault isolation or lifecycle ownership requires them.

```text
Qt Quick presentation + shared design tokens
                 |
Qt models / controllers / capability state
                 |
SystemBackend     WindowManagerBackend     BlurBackend
     |                    |                    |
standard Linux       existing compositor    native effect / owned texture /
services             or window manager      translucent or opaque fallback
     |
optional UKUI adapter
```

Phase 0 deliberately contains no unused backend hierarchy. Phase 1 introduces
the three interfaces above with mock implementations when their first consumers
are built. The table below defines their contracts now.

| Boundary | Owns | Does not own |
| --- | --- | --- |
| Presentation | layout, focus, accessibility, transitions | D-Bus, shell commands, privileged access |
| Models/controllers | stable IDs, selection, search, observable state, request lifecycle | compositor-specific handles |
| System adapters | async service requests, capabilities, errors, reconnection | visual layout |
| Window manager adapter | workspaces, windows, layout requests | rendering app content or implementing a compositor |
| Blur adapter | effect policy, capabilities, surface lifetime, invalidation | arbitrary desktop capture |

## Repository and Qt modules

Current directories have concrete consumers: `.circleci`, `.github`, `docs`,
`qml`, `src/shell`, `tests`, `tools`, `packaging`, and `LICENSES`.
There are no empty placeholder trees. Phase 0 has one executable and one embedded
`KLDE.Shell` QML module, built using `qt_add_qml_module`. QML tests import that
same module. Qt runtime libraries remain dynamically linked to distribution packages.

Later, `src/models` and `src/backends` hold their actual implementations;
reusable UI components stay within a small shell QML module until a real second
consumer warrants another module. No plugin framework, scripting language or
multi-process bus is introduced merely for possible future use.

## System state and D-Bus

Adapters use standard interfaces first: NetworkManager, BlueZ, UPower,
systemd/logind, XDG desktop files and portals, notification specifications,
PipeWire/WirePlumber and power-profiles-daemon where present. These services
have different protocols: audio is not assumed to expose a universal D-Bus API.
Pick a documented public API per service and record that choice before integration.

Initial service snapshots are followed by subscriptions. Calls are asynchronous;
reconnection includes owner-change handling and snapshot reconciliation.
Models distinguish unavailable, pending, confirmed and failed state. Returning
“request accepted” must never be presented as confirmation of a system change.
Unsupported controls are disabled with an accessible explanation.

The early SystemBackend may group the handful of mock quick-setting properties.
Split audio, network and power into their own adapters when real connections
give them independent lifetimes. QML consumes a stable facade, with mock/real
provenance visible in diagnostics rather than branching inside visual controls.

## Compositor independence and Wayland

The standalone preview is an ordinary top-level application. It cannot promise
desktop-layer placement, exclusive zones, global Super-key handling, reliable
global window coordinates or control of other applications on Wayland.

Before session integration, add a surface-host boundary for background, dock,
overlay and popup roles. This is separate from WindowManagerBackend: positioning
the shell's own surfaces and managing other applications are different capabilities.
Evaluate a compositor-supported public layer-shell integration, output tracking,
fractional scaling, input regions, activation and keyboard interactivity together.
Never pass native pointers through QML. Protocol availability is detected at runtime.

No final compositor is selected. UKUI/KWin, wlroots-based and other Wayland
adapters remain candidates. A future KLDE compositor requires its own decision
record and maintenance argument. See [window management](docs/architecture/window-management.md).

## UKUI dependency strategy

First inspect actual Ubuntu Kylin 26.04 packages, API documentation and licensing.
UKUI's existing session orchestration, settings bridges and policy agents may
be useful host services. Their presence and stability are not assumed on every
installation. Reuse them through a replaceable adapter only when a standard
service does not already solve the problem.

Do not fork ukui-panel, import private UKUI QML, embed its UI, assume a UKUI
settings schema, or require the complete distribution. Do not start duplicate
notification daemons, policy agents, network applets or power managers while
testing alongside the host desktop. Selective source reuse needs a documented
reason and provenance review; none is included in Phase 0.

## Security and privacy

The shell runs as the logged-in user and never as root. Use logind and polkit
for authorized session operations; secret storage belongs to a system secret
service or NetworkManager. Do not store credentials or log notification bodies,
network credentials, clipboard data or private filenames by default.

Treat desktop-file arguments, application metadata, notification markup and
external widget data as untrusted. Use argument arrays and appropriate desktop
launch APIs, not interpolated shell commands. Application launching and credential
handling are outside this baseline. Future widgets start as trusted built-ins;
third-party executable plugins need a separate trust and isolation design.

There is no telemetry or hidden network traffic. Weather remains mock data in
Phase 1. A shell surface is not a secure lock screen: any future lock UI must use
a compositor/session locking protocol and a separately reviewed authentication path.

## Rendering and lifecycle

No infinite decorative animation or periodic repaint loop is allowed. Transitions
are finite; hidden views are unloaded or quiescent. The future session adapter
propagates screen-off, suspend and output-removal events into effect and animation
policy. This adapter is not claimed to exist in Phase 0.

Blur policy and caching are described in [blur.md](docs/architecture/blur.md).
Performance acceptance is separate from build speed; see
[the measurement strategy](docs/development/performance.md).
