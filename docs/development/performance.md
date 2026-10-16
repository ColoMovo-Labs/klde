# Performance measurement

Build-machine throughput and shell runtime efficiency are different requirements.
CircleCI is authoritative for correctness; representative desktop performance
requires representative hardware. No performance numbers have been measured yet.

## Reference environment

The first hardware class is an Intel 8th-generation U-series CPU, Intel UHD 620
and 8–16 GB RAM. Record exact CPU/GPU, memory, display resolution/refresh/scale,
compositor, kernel, Mesa, Qt, power profile, AC/battery state, thermal state,
enabled effects and source commit. Compare an unchanged host session against the
same session with KLDE. Disable unrelated workload consistently, not selectively.

## Methods

| Metric | Measurement plan | Evidence and limits |
| --- | --- | --- |
| Idle CPU | allow transitions to settle, collect process CPU over at least 60 seconds; repeat | report mean/distribution and baseline; no instantaneous screenshot as a measurement |
| Idle wakeups | powertop and perf scheduling/timer events where permissions allow | attribute events to KLDE and distinguish compositor/system wakeups |
| Memory | process RSS/PSS from smaps_rollup; heaptrack or massif for investigations | include GPU/scratch textures separately; RSS alone is not total GPU memory |
| GPU activity | intel_gpu_top on real Intel hardware plus idle baseline | separate render/blitter/video activity; record sampling overhead |
| Frame time | Qt Quick profiler and compositor presentation timing; RenderDoc for a targeted frame | distribution, missed frames and p95/p99; capture tools change performance |
| Blur | fixed scene/area/scale; Off/Low/Medium/High, static and damaged source | GPU time, texture memory, damage frequency and visual edge quality |
| Startup | repeat launch to first presented usable frame; warm/cold conditions stated | process creation to ready event, not only main() entry |
| Launcher latency | timestamp input event to first usable focused search/result frame | repeated trials, warm/cold model, input method and result count |

Set numeric budgets after a measured baseline and document them in a follow-up
ADR. “Comfortable” is a product goal, not a fabricated benchmark. Inspect both
opaque/reduced-motion and full-effect configurations.

## Idle regression checks

After opening/closing a surface, frame submissions should stop once finite
transitions and pending resource work finish. A diagnostic frame counter can catch
accidental continuous rendering, but zero client frames alone does not prove zero
CPU, GPU work, wakeups or compositor activity. Avoid periodic clock/weather updates
in a controlled idle scenario. Do not disable real lifecycle events to pass a test.

The Phase 1 cloud frame check exposed an invisible ListView highlight-tracking
item resizing after the popup's own transition had finished. Qt's documented
[highlight move/resize controls](https://doc.qt.io/qt-6/qml-qtquick-listview.html#highlightResizeDuration-prop)
default to a velocity of 400 pixels/second and unconstrained duration. The preview
sets both velocities to -1 and both durations to `Tokens.motionFast`; reduced
motion makes them zero. Inspect built-in view behavior as well as visible QML
animations. An observation of extra frames over one second does not by itself
prove an infinite animation or establish an idle CPU measurement.

The diagnostic disables text-cursor blinking only for the controlled observation.
Normal input retains the platform cursor. Current captures and exact frame counts
are in [phase-1.md](phase-1.md).

## Cloud correctness and later infrastructure

U939-class Intel integrated graphics is a low-end reference, not a product limit.
Hardware acceptance must include Intel/AMD integrated graphics, AMD/NVIDIA
discrete and hybrid systems, desktops without batteries, multiple monitors,
fractional/high DPI and 60/120/144 Hz displays where supported. Record available
brightness, power-profile, GPU and output capabilities; unsupported controls are
absent rather than silently simulated. Compare default scene costs with blur
enabled at the selected quality, and separately measure the explicit Off fallback.

Standard CircleCI containers use a software Qt Quick backend or Mesa llvmpipe.
Nested Weston tests protocol/startup behavior; Xvfb/llvmpipe exercises the OpenGL
rendering path. Neither is an Intel GPU benchmark or a replacement for output,
input, suspend and compositor tests on a real session.

Software rendering comparisons may detect regressions on a stable executor,
but identify them as software correctness/regression measurements. Record resource
class and environment; avoid cross-machine timing claims. A dedicated real-GPU
runner can be added later with controlled power/thermal/display settings, raw
traces and an auditable commit-to-result mapping.

Report failures and inconclusive results as such. Preserve logs and screenshots
without private desktop contents; use synthetic scenes. Never infer visual polish
or low power use merely from a successful CI job.

The expanded cold `.deb` runtime check exposed the limits of a fixed 700 ms
startup wait: the blur view still submitted transition/resource frames afterward.
The diagnostic now requires at least 700 ms plus a 300 ms quiet interval before
starting the unchanged one-second audit (maximum two frames). Every settling
frame restarts the quiet timer; continuous rendering reaches the 12-second
timeout and fails. Ordinary runtime adds no such timer. This is a correctness
gate, not a claim that cold-renderer latency or hardware performance is solved.
