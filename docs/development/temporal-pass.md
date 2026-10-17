# Temporal-axis development pass

This branch is a mock-first product/architecture update. It does not exit mock
mode, generate a distribution, replace a compositor or install Waydroid.

After obtaining a matching cloud-built binary:

```sh
klde-shell --view temporal
klde-shell --scenario sunset --ambient
klde-shell --scenario starry-night --ambient
klde-shell --scenario wallpaper-depth-enabled --view wallpaper-effects
klde-shell --scenario segmentation-failed --ambient
klde-shell --scenario lock-screen-blur-enabled --view lock-preview
klde-shell --scenario waydroid-ready --view launcher
```

Working mode is the default; Temporal settings or the Mock Lab enable Ambient.
Expanded Quick Settings and the Mock Lab link to Temporal, Wallpaper Effects and
Android source settings. New scenario fixtures cover six phases, depth success/
failure, linked lock, power saver, no-battery and Android availability.

## Validation status

Source implementation and formatter preparation are local work only. No local
compilation, tests, lint or integration validation is permitted by this project's
cloud-first policy. The frozen Visual Lab captures are from the previously green source `752af8c`.
They remain historical evidence for that revision.

This new pass requires its own pushed CircleCI run. Do not inherit the prior
commit's green status or reuse its pictures as evidence for changed geometry.
The smoke script now requests the new panels; the matrix adds 14 new cases to the
previous 72. Tests add time stepping, cache invalidation/fallback, scene restoration,
optional app source and stopped-session behavior. Their results are unverified
until the cloud run completes.

Review the new screenshots at 1366×768, full HD, QHD, HiDPI, ultrawide and portrait;
check centered time, group wrapping, telemetry boundaries, display numeral/colon
alignment, translated labels, focus and fallback. Only then select replacement
baselines. Keep real GPU profiling, assistive technology and owner design acceptance
separate. The current lock page is a visual study, not a secure locker.
