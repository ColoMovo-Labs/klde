# Temporal-axis development pass

This document records the earlier temporal-axis implementation and points to
the current visual correction. The branch remains mock-first: it does not
replace a compositor, install Waydroid, call a weather service or generate a
distribution.

The current design and implementation record live in
[`docs/development/temporal-v2.md`](temporal-v2.md) and
[`docs/design/temporal-capsule.md`](../design/temporal-capsule.md). The public
study surface is:

```sh
klde-shell --view temporal-study --size 1440x1000
```

Useful mock fixtures remain available for manual review:

```sh
klde-shell --scenario sunset --ambient
klde-shell --scenario starry-night --ambient
klde-shell --scenario wallpaper-depth-enabled --view wallpaper-effects
klde-shell --scenario segmentation-failed --ambient
klde-shell --scenario lock-screen-blur-enabled --view lock-preview
klde-shell --scenario waydroid-ready --view launcher
```

The temporal correction now has six original landscape states in compact,
standard and expanded forms, an independently centered ribbon, a large clock
mode, focus mode, and explicit light/night wallpaper resources. Auto phase
selection combines scenario time with weather: rain, thunderstorm and snow use
the rain layer; fog and overcast conditions use the cloudy layer. Manual phase
selection remains an art-direction override.

Short ambient surfaces reserve the center column for the clock. The lower
weather/media affordances are hidden below the media minimum height so they
cannot collide with the centered time stack.

## Validation boundary

Source edits and formatter preparation are local-only. Compilation, QML tests,
static analysis, packaging, integration and image capture are authoritative
only when reported by CircleCI. A captured pipeline must be identified by its
commit and all required jobs must be green before its images are used as public
visual evidence.

The one-second llvmpipe idle-frame check detects continuous redraw; it is not a
CPU, memory, frame-rate, battery or representative Intel GPU benchmark. Native
GPU profiling, assistive technology review and owner visual acceptance remain
separate follow-up work.
