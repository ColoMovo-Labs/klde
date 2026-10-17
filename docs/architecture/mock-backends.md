# Scenario providers and presentation contracts

The current phase remains mock first. Linux service policy, login integration,
compositor implementation and distribution engineering are not part of this pass.

QML -> Qt-facing contracts -> mock provider -> validated scenario snapshot.
Future live adapters should satisfy the same presentation contract, not expose
hardware/process logic to visual components.

| Interface | Current implementation | Published contract |
| --- | --- | --- |
| TimeBackend | MockTimeBackend | date/time, phase, season, weather mood |
| TelemetryBackend | MockTelemetryBackend | stable CPU/memory/temperature/battery cells, availability, severity |
| WallpaperEffectsBackend | MockWallpaperEffectsBackend | requested/effective settings, cache validity, asset URLs, preview actions |
| WaydroidBackend | MockWaydroidBackend | optional availability/session/index preference, simulated start/stop |

These QObject interfaces are owned by each ShellServices instance. They reference
the same SystemStateModel, so scenario reset and cross-panel controls stay coherent.
There are no worker threads, polling loops or real subprocesses in these mock
providers. The shell does not instantiate a privileged helper. A future provider
can publish independently; QML depends on base interface types.

The scenario schema adds temporal phase, wallpaper cache/effect preferences and
optional Android source state. All leaves retain strict type/range/enum checks.
The catalog now includes morning/day/dusk/night, depth-ready/failure, cached lock
and Android-ready fixtures. Applying a scenario starts from the complete baseline;
weather network consent and optional source state do not leak into the next one.

Branding is separate from technical identity. `Branding.qml` centralizes display
name, expanded name and replaceable mark. Localized strings use `{brand}`. QML
URIs, executable/package names, desktop IDs and cache namespace remain stable
technical identifiers; a visual rebrand must not silently migrate user state or
break ABI/packaging. The current KLDE name is provisional.

Cloud acceptance must exercise time-step propagation, cache mismatch/failure,
power-policy degradation/restoration, Android source insertion/removal and rejected
launches while stopped, plus grouped ribbon boundaries. All compilation, Qt tests,
QML tests, analysis and new captures remain CircleCI-only. Local source review and
formatting do not substitute for those results.
