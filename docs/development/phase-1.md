# Phase 1 shell preview

Phase 1 follows the green minimal baseline `418ea56`. This is an ordinary Qt
application window with mock services, not an installed desktop session. Cloud
validation for this feature is recorded below when results are available.

## Expanded foundation

The expanded prototype adds editable Power Scenes, session-rebindable application
shortcuts, default blur of KLDE-owned wallpaper regions and opt-in weather through
a provider abstraction. Quick settings opens scene preferences; the round weather
widget opens privacy/provider settings. `--view power-scenes` and `--view weather`
open those views for cloud capture without enabling online weather.

All three default scenes retain blur; the Performance and Power Saver defaults
use Low quality. Preferences support per-scene theme, blur, transparency, shadows,
motion and reset, with shared user accent presets. No CPU/GPU/refresh-rate control
is shown without a real capability. Shortcuts validate conflicts and remain
application-local/session-only. Weather has explicit city/consent, offline/stale
state and bounded requests; no live provider check is claimed by fixture tests.

CircleCI now also defines an independent Fedora build and a real Debian-package
runtime test in a fresh container. Their current-head results are tracked in the
PR; the historical six-job acceptance below applies only to the stated revision.

## Components and controls

- Centered floating dock: six pinned mock applications, active/running indicators,
  pointer feedback, keyboard focus and launcher access.
- Search-first launcher: C++ application/filter models; typing, Up/Down, Enter,
  Escape and pointer activation. Selection changes only the mock catalogue.
- Upper-right quick settings: mock brightness, volume, wireless, Bluetooth,
  night light, power profile and session action; appearance and motion controls.
- Weather widget: one trusted built-in widget hosted by a Loader; mock data by
  default, with explicit city/consent for optional online weather. No external
  widget execution is supported.
- Workspace indicator: five stable IDs with floating, tiled, mixed and custom
  labels. Selection updates a mock backend, never another application's windows.
- OSD foundation: an interaction-triggered, finite notice for mock changes.
- Blur laboratory: a bounded, explicitly owned-content GPU experiment. Normal
  shell panels filter only the owned wallpaper when supported and retain an
  opaque fallback. Native backdrop support is unavailable.

```sh
klde-shell                       # ordinary standalone preview
klde-shell --view launcher
klde-shell --view quick-settings --dark
klde-shell --view blur
```

Within the preview, Ctrl+Alt+Space opens the launcher, F2 opens quick settings,
Ctrl+Alt+B opens the blur laboratory, and Ctrl+Alt+R toggles reduced motion.
These are application shortcuts, not global desktop shortcuts. Escape dismisses
a popup; closing restores focus to the invoking part of the shell.

The clock is fixed preview content. Weather defaults to synthetic data; explicit
city/consent can enable the experimental provider. Power and application
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
after at least 700 ms and a subsequent 300 ms without a submitted frame, then
rejects more than two. Continuous rendering cannot reach the quiet gate and
fails the 12-second overall timeout. This accommodates cold software rendering
without counting unfinished transitions as idle activity. Launcher cursor
blinking is disabled for this static-rendering diagnostic. Normal interaction
uses the platform cursor; the scroll indicator is static. Native list highlight
tracking also uses the finite motion tokens, including zero duration in reduced motion.
This is a bounded
regression check, not a desktop idle CPU, wakeup, power or GPU benchmark.
Ordinary startup has no diagnostic timers or periodic repaint loop.

All six CircleCI jobs passed for source commit
`46619fc`: [pipeline 13](https://app.circleci.com/pipelines/circleci/3oxaeukVqAvAfF4HxntS1j/9f38edc2-e2b3-4a5a-b510-656e0f838973/13/details?useNewPipelines=true&workflowId=b9eac2ba-fece-43da-9339-2fc74cf1a24f).
The actual PR configuration was checked through the CircleCI API, including
all-source clang-tidy and the launcher interaction step. The environment was
Ubuntu 26.04, Qt 6.10.2 and Mesa 26.0.8 llvmpipe. Local compilation, tests and
static analysis were not used as validation.

| Scenario | Evidence | Settled one-second frame count |
| --- | --- | --- |
| Offscreen/software | startup and PNG | not audited on this path |
| Nested Weston/Wayland/software | startup and PNG | not audited on this path |
| Light desktop / llvmpipe | [actual capture](phase-1-desktop.png) | 0 |
| Light quick settings | [actual capture](phase-1-controls.png) | 0 |
| Keyboard-first launcher | [actual capture](phase-1-launcher.png) | 0 |
| Owned-content GPU blur | [actual capture](phase-1-blur.png) | 0 |
| Dark quick settings | [actual capture](phase-1-dark.png) | 0 |

All five captures were visually inspected. Dark ink variants and semantic palette
roles improve icon/control contrast; mock weather attribution remains readable.
The blur sample visibly filters only the embedded original wallpaper. These
screenshots represent the identified source revision, not a final desktop design.

The frame check caught a long native ListView highlight-tracker resize transition,
even though the tracking item itself draws no highlight. Its default speed-based
animation was not an infinite loop. Move/resize durations now follow the finite
motion tokens; reduced motion sets them to zero. See
[the performance note](performance.md#idle-regression-checks).

A later source cleanup ties queued graphics callbacks and diagnostic timers to
their QObject owners. The latest commit must still pass the same required checks;
[PR #1](https://github.com/ColoMovo-Labs/klde/pull/1) carries the current-head result.

## Remaining boundaries

Real audio/network/power services, screen-off/suspend integration, layer-shell/session hosting,
window management, native compositor blur, installed application discovery and
persistent configuration remain later work. Qt's software scene graph uses the
unfiltered source in the laboratory. No Intel UHD 620 performance claim is made.
Keyboard paths and scalable tokens are present; comprehensive screen-reader,
contrast, multi-output and 200% text acceptance still require dedicated review.

## Language, voice and input preview

```sh
klde-shell --locale zh_CN --view quick-settings
klde-shell --locale en --voice cute --view language
klde-shell --locale zh_CN --voice cute --view language
klde-shell --view input
```

The EN/拼 indicator opens the mock selector and Language & Input settings. Locale
and voice are independent in-memory preferences; existing labels react to changes.
Fcitx 5 availability is read-only session-bus detection, not engine installation
or confirmation of active Pinyin. Selection remains simulated; the text area
uses the host's normal Qt input context. Theme prototypes are installed but not
automatically selected. No host locale, IME configuration or global binding is
changed. The launcher default uses Ctrl+Alt+Space to avoid taking the commonly
used Ctrl+Space IME binding inside this preview.

Stable English/Chinese JSON catalogs and sparse Cute overrides are embedded
resources. CI checks missing/duplicate IDs, placeholders and protected namespaces.
Wayland/XCB interaction tests and bilingual captures are correctness evidence;
manual mixed-application IME, CJK scaling and assistive-technology acceptance
remain open. See the [input test matrix](../architecture/input-methods.md).

The [expressive bilingual follow-up](expressive-language.md) records the revised
controls, language/input captures, dual-display interaction suite and clean `.deb`
runtime evidence at their actual source revision. Historical images above are
retained rather than relabelled as the new implementation.
