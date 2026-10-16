# Phase 1 shell preview

Phase 1 follows the green minimal baseline `418ea56`. This is an ordinary Qt
application window with mock services, not an installed desktop session. Cloud
validation for this feature is recorded below when results are available.

## Components and controls

- Centered floating dock: six pinned mock applications, active/running indicators,
  pointer feedback, keyboard focus and launcher access.
- Search-first launcher: C++ application/filter models; typing, Up/Down, Enter,
  Escape and pointer activation. Selection changes only the mock catalogue.
- Upper-right quick settings: mock brightness, volume, wireless, Bluetooth,
  night light, power profile and session action; appearance and motion controls.
- Weather widget: one trusted built-in widget hosted by a Loader; fixed weather
  data and no network request. No external widget execution is supported.
- Workspace indicator: five stable IDs with floating, tiled, mixed and custom
  labels. Selection updates a mock backend, never another application's windows.
- OSD foundation: an interaction-triggered, finite notice for mock changes.
- Blur laboratory: a bounded, explicitly owned-content GPU experiment. Ordinary
  shell panels use opaque surfaces. Native backdrop support is unavailable.

```sh
klde-shell                       # ordinary standalone preview
klde-shell --view launcher
klde-shell --view quick-settings --dark
klde-shell --view blur
```

Within the preview, Ctrl+Space opens the launcher, F2 opens quick settings,
Ctrl+Alt+B opens the blur laboratory, and Ctrl+Alt+R toggles reduced motion.
These are application shortcuts, not global desktop shortcuts. Escape dismisses
a popup; closing restores focus to the invoking part of the shell.

The clock and weather are deliberately fixed mock content. Power and application
buttons report preview actions; they never shut down the host or start programs.

## Module and ownership boundaries

`KLDE.Shell` contains presentation and tokens. `KLDE.Backends` registers the
per-engine `Shell` facade and typed contracts/models in C++. The executable
instantiates the embedded modules; distribution Qt libraries remain dynamic.
There is no mutable process-global service instance.

`SystemBackend` groups the small mock control set until real audio/network/power
adapters have independent connection lifetimes. `WindowManagerBackend` uses
stable opaque IDs and reports capabilities. Unsupported scrolling and persistent
rules return failure. `BlurBackend` separates native backdrop from owned texture
support; graphics initialization, invalidation and preview visibility update its
capability state. System integration does not live in visual QML components.

Artwork is original, generated from the project's own geometric SVG definitions
in `tools/generate-assets.py`. Icons and the First Light wallpaper are licensed
CC BY-SA 4.0; see [assets/README.md](../../assets/README.md).

## Cloud acceptance

The CircleCI feature pipeline must compile the modules and test backend state
validation, application filtering, unsupported window requests, and blur fallback.
Qt Quick Test covers launcher focus, typing, Enter and Escape as well as tokens.
Smoke tests cover offscreen/software, nested Weston/Wayland/software, and
Xvfb/OpenGL/llvmpipe. Additional captures show launcher, controls, dark controls
and the owned-content blur laboratory.

In diagnostic mode only, `--audit-idle` counts submitted frames during one second
after a 700 ms settling interval and rejects more than two. Launcher cursor
blinking must be disabled for this static-rendering diagnostic. This is a bounded
regression check, not a desktop idle CPU, wakeup, power or GPU benchmark.
Ordinary startup has no diagnostic timers or periodic repaint loop.

Status: implementation prepared; the feature pipeline and capture review are
pending. Do not infer successful validation from this document's existence.

## Remaining boundaries

Real service calls, screen-off/suspend integration, layer-shell/session hosting,
window management, native compositor blur, installed application discovery and
persistent configuration remain later work. Qt's software scene graph uses the
unfiltered source in the laboratory. No Intel UHD 620 performance claim is made.
Keyboard paths and scalable tokens are present; comprehensive screen-reader,
contrast, multi-output and 200% text acceptance still require dedicated review.
