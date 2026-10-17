# Temporal Capsule / 时序胶囊

Time is the primary anchor. The capsule is a quiet geometric micro-scene, not a
miniature animated landscape. A 44 px scene uses a disc/crescent, a horizon, a
cloud bar and at most three static stars or rain marks. Four small seasonal dots
add rhythm; accessible text names the selected phase and season. Color is not
the only information channel.

## Two related proposals in the prototype

1. **Compact ribbon capsule**: restrained time text, geometric scene and seasonal
   dots, 176/192 × 66 logical pixels. It stays on the viewport centerline.
2. **Rich capsule**: the same grammar at 320 × 84, with a phase label. Ambient
   composition hides its duplicate time because the display clock already owns
   the center. The Temporal settings page shows the complete rich form.

Lighting studies: morning light, daylight, sunset, rainy dusk, starry night and
moonlit night. Weather mood is an independent cue within the lighting study. The mock backend derives an automatic phase from scenario time
with optional overrides. Seasons use northern-hemisphere months as a labelled
fixture. These are illustrative mood states; there is no location, ephemeris,
sunrise/sunset calculation or physical moon phase claim.

## Time contract and motion

`TimeBackend.reading` exposes ISO date/time, hour/minute strings, phase, season,
night state and weather mood. `MockTimeBackend` follows the central scenario and
manual one-minute advances. It has no timer, no network request and no particles.
A future live provider should publish on minute boundaries and relevant clock,
timezone, resume or weather changes. It must not cause per-second repainting.
Suspend its visual delivery when no visible consumer needs it, then refresh once
on resume. Astronomical data would require explicit location/timezone semantics.

Only relevant geometry/tint changes receive finite transitions. Hidden scenes
and reduced motion bypass those transitions. A static phase has no active loop,
shader animation or continuously redrawn Canvas.

## Ambient and working modes

Working mode uses a 56 px display clock beneath the ribbon and keeps application
context prominent. The welcome message is limited to an empty preview desktop.
Ambient mode opts into a 184 px central display clock, date, weather, rich capsule
and media. Text width and height budgets scale the clock for the available surface. Short
windows drop the rich mood/weather detail, then the media card, before allowing
the composition to overlap the ribbon or dock.
Neither mode is a secure lock screen. Automatic idle transitions are future work;
the prototype switches explicitly in the Mock Lab or Temporal page.
