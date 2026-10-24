# Architecture

Status: Phase 1's mock-first shell prototype is implemented; Phase 2 backend
preparation and Fedora/KWin validation are in progress. See [the prototype
guide](docs/development/phase-1.md) and [the Fedora runtime record](docs/development/fedora-runtime.md).

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
There are no empty placeholder trees. The process has one executable and two
embedded QML modules, `KLDE.Shell` for presentation and `KLDE.Backends` for the
per-engine facade and C++ models/contracts, built using `qt_add_qml_module`.
QML tests import these same modules. Qt runtime libraries remain dynamically
linked to distribution packages.

`src/models` and `src/backends` hold application models and mock contracts;
reusable UI components stay within a small shell QML module until a real second
consumer warrants another module. No plugin framework, scripting language or
multi-process bus is introduced merely for possible future use.

## Upstream and distribution boundaries

The upstream KLDE desktop is independent of a future Ubuntu LTS-based distribution.
Ubuntu/Kylin receives first-class integration and Debian packages; Fedora receives
its own cloud source-build gate and eventually RPM packaging. Other distributions
remain source portability targets, with community packages distinguished from
officially tested combinations. Distribution defaults belong in downstream
packages, not hardcoded service paths in shell presentation.

Capabilities are discovered per service and output. Do not assume Intel graphics,
a battery, a discrete GPU, writable brightness, refresh-rate switching or
power-profiles-daemon. Intel/AMD/NVIDIA, hybrid graphics, desktop/laptop,
multiple outputs, scaling and high refresh rates belong in the hardware acceptance
matrix. U939-class hardware is a low-end sanity baseline, not the product boundary.

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

## Display, language and input boundaries

KLDE is Wayland first and X11 compatible. Qt QPA supplies the ordinary application
window path; QML does not call Xlib/XCB or raw Wayland APIs. DisplayServerBackend
reports the active QPA path and explicit unsupported session capabilities. Native
adapters stay under `src/platform`; no empty Wayland/X11 implementation is created.
See [display-protocols.md](docs/architecture/display-protocols.md). KWin is the
first engine candidate without adopting Plasma UI; the adapter must distinguish
upstream KWin 6 from the deepin/Lingmo KWin lineage and probe capabilities.

LocaleVoiceModel owns embedded ID catalogs, `en`/`zh_CN`, Standard/Cute fallback
and tone locks. It changes shell presentation in memory, not the system locale.
InputMethodBackend is separate: Fcitx5Backend performs asynchronous read-only
D-Bus owner detection, with simulated method choices and no host switching.
The shell indicator and Language & Input page use these contracts. Fcitx owns
preedit, dictionaries and candidate compatibility; the original light/dark theme
prototype is manually selectable. Native candidate surfaces, global IME control
and Power Scene synchronization require later integration and interactive tests.
See [i18n](docs/architecture/i18n.md) and [input methods](docs/architecture/input-methods.md).

GlobalShortcutBackend, ScreenBackend, ClipboardBackend and ScreenshotBackend are
reserved responsibilities, not implemented services. Add them when real consumers
and supported APIs exist. Platform-specific handles never cross into presentation.

## Compositor independence


The standalone preview is an ordinary top-level application. It cannot promise
desktop-layer placement, exclusive zones, global Super-key handling, reliable
global window coordinates or control of other applications on Wayland.

Before session integration, add a surface-host boundary for background, dock,
overlay and popup roles. This is separate from WindowManagerBackend: positioning
the shell's own surfaces and managing other applications are different capabilities.
Evaluate a compositor-supported public layer-shell integration, output tracking,
fractional scaling, input regions, activation and keyboard interactivity together.
Never pass native pointers through QML. Protocol availability is detected at runtime.

KWin is the first real adapter target. Upstream KWin 6, deepin/Lingmo KWin and
other Wayland engines remain separate capability profiles. A new KLDE compositor
is deferred unless a measured KWin blocker survives the adapter prototype. See
[window management](docs/architecture/window-management.md) and the
[KWin adapter boundary](docs/architecture/kwin-adapter.md).

Shortcut actions have stable IDs and configurable application-local bindings;
global shortcuts require a later compositor/portal adapter. See
[shortcut policy](docs/architecture/shortcuts.md). Power Scenes coordinate
capability-based system policy with visual preferences, while weather has a
provider boundary and explicit online consent. See [power scenes](docs/architecture/power-scenes.md)
and [weather](docs/architecture/weather.md).

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

UKUI and LingmoOS are the first app ecosystems to evaluate, not mandatory runtime
dependencies. Each candidate records direct use, theming, adaptation/fork or
behavior-only reference, with exact license and dependency evidence in
[the application framework](docs/architecture/apps.md). Shell UI and app branding
remain independent.

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

There is no telemetry or hidden network traffic. Weather defaults to mock data;
the experimental online provider requires explicit consent and a city, with
attribution, cooldown and failure state. A shell surface is not a secure lock screen: any future lock UI must use
a compositor/session locking protocol and a separately reviewed authentication path.

## Rendering and lifecycle

No infinite decorative animation or periodic repaint loop is allowed. Transitions
are finite; hidden views are unloaded or quiescent. The future session adapter
propagates screen-off, suspend and output-removal events into effect and animation
policy. This adapter is not claimed to exist in Phase 0.

Blur policy and caching are described in [blur.md](docs/architecture/blur.md).
Performance acceptance is separate from build speed; see
[the measurement strategy](docs/development/performance.md).

## Temporal-axis presentation contracts

The next mock-first pass adds typed time, composite telemetry, cached wallpaper
and optional Android-source contracts. See [mock providers](docs/architecture/mock-backends.md),
[cached wallpaper processing](docs/design/wallpaper-depth.md) and
[Waydroid architecture](docs/architecture/waydroid.md). All heavy wallpaper work is
outside the live shell. The current provider uses pre-authored resources only.
Public branding is provisional and centralized; stable internal IDs stay separate.
Future visual packs should supply validated tokens/assets, not arbitrary QML or
privileged behavior. Premium packs, donations and commerce remain future planning.
