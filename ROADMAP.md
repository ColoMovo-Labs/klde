# Roadmap

Phases describe acceptance gates, not dates or release promises.

The current product target is a basically usable daily desktop on Fedora 44,
with Ubuntu retained as the primary supported distribution. Follow the
[daily-use acceptance gates](docs/development/daily-use.md), including real
native surfaces, application/window state and session essentials. The optional
[Lingmo Calculator engine port](apps/calculator/README.md) starts app migration;
headless CI or a preview RPM does not imply daily-use readiness.

| Phase | Scope | Exit evidence |
| --- | --- | --- |
| 0 — Foundation | Public repository, license/provenance, architecture/design, contribution workflow, CircleCI, minimal Qt executable and startup tests | repository and CI configured; all core jobs pass for an identified commit; baseline reviewed |
| 1 — Shell prototype | Tokens, dock, launcher, controls, weather, workspace UI, editable mock Power Scenes and default owned-content blur | coherent Qt prototype, keyboard tests, actual light/dark captures, bounded rendering checks |
| 2 — System integration | Time/date, UPower battery, brightness, PipeWire volume, NetworkManager, BlueZ, opt-in weather, app discovery, notifications, then WM integration | capability/error/reconnect tests; confirmed state; no private data in logs |
| 3 — Settings and Power Scenes | Persistent appearance/input/accessibility and customized scenes; capability-based power, display and graphics adapters | settings migration, partial failure and permissions; hardware evidence |
| 4 — Apps and sessions | UKUI/Lingmo app decisions; startup/output/suspend, portals and policy agents | package/API/license assessment, recovery, no duplicate daemons; lock reviewed separately |
| 5 — Packaging and Fedora | Debian packages, Fedora source CI and later RPM packaging; source portability on other distros | clean install/runtime/remove tests, matching source/notices, tested version matrix |
| 6 — Advanced window management | KWin-first adapter, per-workspace Floating / Classic Tiling / Scrolling Tiling / Mixed policies, window rules and remembered geometry | engine-family/API/protocol matrix; capability/reconnect/multi-output tests; exact KWin profile justified by ADR |
| 7 — Future distribution | Separate Ubuntu LTS downstream defaults, apps, branding and eventual ISO | security/update ownership, provenance and recovery; upstream remains independent |

Classic Tiling first researches KWin's public tile/script APIs. Scrolling Tiling
and additional algorithms remain KLDE-owned planning extensions after a basic
adapter works; they must not dictate a premature compositor fork.
Notification center, OSD, desktop widgets and session UI grow with actual service
capabilities rather than appearing as a collection of disconnected demonstrations.

Current state: Phase 0 is published at `ColoMovo-Labs/klde`. All six CircleCI jobs
passed for baseline `418ea56`; the Phase 1 build gate is satisfied.
See [the phase-0 handoff](docs/development/phase-0.md).

Phase 1 is implemented on a topic branch with mock services; all six cloud jobs
passed for `46619fc`. Captures and bounded idle-rendering results are recorded in
[phase-1.md](docs/development/phase-1.md). PR review and subsequent current-head
checks remain part of acceptance; full desktop/hardware accessibility acceptance
is not implied by a passing headless pipeline.

The expanded foundation adds Fedora CI, real `.deb` validation, optional weather,
Power Scenes and configurable shortcuts. Source preparation is not cloud
acceptance; the current PR records each new job's result. RPM packages, Arch CI,
global shortcuts, native compositor blur and a distribution image remain future work.

## KLDE 0.3 — Language, Voice & Input

[GitHub milestone](https://github.com/ColoMovo-Labs/klde/milestone/1) groups cross-cutting shell work; it is not a release date or a
version bump. Initial scope: stable bilingual IDs, independent locale/voice state,
sparse Cute fallback and protected namespaces; selector and Language & Input
prototypes; Fcitx 5 read-only detection, mock indicator and original light/dark
theme; nested Wayland and Xvfb/XCB correctness checks.

Later acceptance requires real Fcitx switching, Pinyin/Rime setup guidance,
interactive mixed-app preedit/candidate/punctuation testing, persistent preferences
and optional appearance synchronization. Native candidate surfaces are excluded.
See [display](docs/architecture/display-protocols.md),
[i18n](docs/architecture/i18n.md), [input](docs/architecture/input-methods.md) and
ADRs 0011–0015. ADRs 0009–0010 already record weather and shortcuts and retain
their historical identifiers. Chinese and English are both primary product paths.

The mock-design milestone now prioritizes a temporal central axis, semantically
grouped ribbon, composite telemetry, dedicated display numerals and distinct
Ambient/Working composition. Cached wallpaper depth and optional Android app
sources are being prototyped as contracts before real providers. Cloud acceptance
and owner visual review remain required before moving into live integration.
