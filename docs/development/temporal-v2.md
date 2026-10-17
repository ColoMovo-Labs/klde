# Temporal landscape correction

## Inspection before changes

The existing `StatusRibbon` centers time independently, but a tall monitoring group
sets a 66 px band and side Flows wrap. `TemporalCapsule` was a round icon next to
text. `Main` always painted a second clock in Working mode. `AmbientDesktop`
stacked a clock, date, weather, second temporal button and media in one column.
`WallpaperLayers` dimmed the day SVG. These are the concrete correction points;
Dock, notifications, existing services and preview pages remain in place.

## Staged work

A. Inspect existing QML, tokens, state schema and cloud capture pipeline: done.
B. Original six-scene landscape, three sizes, one comparison surface:
`klde-shell --view temporal-study --size 1440x1000`.
C. Rebalance independent left/center/right zones with explicit degradation.
D. Optional clock/focus modes, heavier OFL display face and a true night palette.
E. Cloud interactions, four logical resolutions, real capture inspection.

SVGs are original layered geometry (CC BY-SA 4.0), loaded once at requested
physical size and cached. Sun/moon transforms are separate. No Canvas, per-frame
astronomy, blur, particle system or image generation. Mock celestial data is
explicitly simulated; a future real provider must supply independent nullable
rise/set data, moon visibility, phase, season and weather provenance.

Validation and preview provenance are filled from CircleCI, not local builds.

## Implementation record

C. Independent center and bounded side lanes reuse the registry; graded folding
replaces whole-ribbon scaling. Monitoring fits the row as a shared 2×2 control.
D. Default/Clock/Focus selection reuses the Temporal detail page. Rubik 800 has
pinned OFL provenance and is packaged with its notice. Four original wallpaper
families have explicit night resources; scene cache studies have night variants.
Night surfaces, ink, borders, shadows and accents use an independent blue/indigo/
moonlight palette, without a global day-wallpaper dimming veil.
E. Cloud validation is recorded against the exact pushed commit; no local build,
tests or lint are performed.

## Limits

Time, weather, astronomy, resource telemetry and all system actions remain Mock.
The existing wallpaper-cache and optional-app contracts are preserved, not
expanded into integrations. No Wayland compositor, WindInput, real weather,
Waydroid process or segmentation model is added in this correction.

A one-second scene-graph idle-frame count in llvmpipe detects continuous redraw;
it is not a CPU, RAM, FPS or real GPU benchmark. Representative hardware power,
frame latency, assistive technology and native speaker visual review remain open.

## Research

- [Rubik official source and license](https://github.com/google/fonts/tree/8b0a1d0f5983c89bc2b93f1b5fb55f9e252744b5/ofl/rubik)
- [Qt image caching and SVG sizing](https://doc.qt.io/qt-6/qml-qtquick-image.html)
- [Qt performance considerations](https://doc.qt.io/qt-6/qtquick-performance.html)

No external reference artwork or Google proprietary font is copied.

The first cloud comparison (source `61e8f7a`, pipeline 46, integration 339)
confirmed six distinguishable landscapes but exposed incomplete path clipping:
cloud and rain layers could escape the pill. The offline generator now keeps a
size-specific SVG `clipPath` around every layer and still bakes convex terrain
intersection into vector paths. It adds no runtime mask/FBO. The generator is
`tools/generate-temporal-assets.py`.

## Cloud evidence

Pipeline 50, source `775d728`, passed the eight required jobs: Fedora build,
configure/build, static analysis, unit tests, QML tests, Wayland/XCB integration,
packaging and clean Debian runtime installation. The integration manifest contains
95 matrix records, all with exit code 0. Both interaction logs report 26 QML tests
passed and 0 failed; ribbon center deviation is 0 at widths 640 through 3440 and
all three density modes. The llvmpipe audit settled with 0 idle frames, which is
an idle-rendering check rather than a hardware performance result.

The reviewed captures and their SHA-256 values are in
[`docs/previews/temporal-v2/README.md`](../previews/temporal-v2/README.md).
