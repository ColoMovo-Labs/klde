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
`klde-shell --view temporal-study --size 1440x1000`. Cloud preview pending.
C. Rebalance independent left/center/right zones with explicit degradation.
D. Optional clock/focus modes, heavier OFL display face and a true night palette.
E. Cloud interactions, four logical resolutions, real capture inspection.

SVGs are original layered geometry (CC BY-SA 4.0), loaded once at requested
physical size and cached. Sun/moon transforms are separate. No Canvas, per-frame
astronomy, blur, particle system or image generation. Mock celestial data is
explicitly simulated; a future real provider must supply independent nullable
rise/set data, moon visibility, phase, season and weather provenance.

Validation and preview provenance will be filled from CircleCI, not local builds.
