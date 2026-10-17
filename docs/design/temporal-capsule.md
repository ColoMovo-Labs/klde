# Temporal Capsule 2.0 / 时序胶囊

The time lives inside a horizontal landscape. It is no longer a circular weather
icon placed next to a clock. One component owns three layers: a cached gradient
sky; separately positioned sun/moon and cached mountain/cloud/star/rain geometry;
and time over a local dark gradient for legibility. Three mountain distances
carry the silhouette across the full pill. No cultural ornaments are introduced.
All scene artwork is original CC BY-SA 4.0 geometry.

| Scene | Sky / terrain / celestial cues |
| --- | --- |
| Morning | Lavender sky, warm gold sun, soft violet ridges |
| Sunny afternoon | Pale blue, small white clouds, high bright sun |
| Sunset | Purple sky, orange horizon, low sun behind the ridge |
| Rainy dusk | Blue grey, layered clouds and a few static rain marks |
| Starry night | Deep blue, five small stars, low luminance ridges; no implied moon |
| Moonlit night | Cyan moonlight, independent crescent, quiet teal ridges |

The historical fixture ID `cloudy-day` is retained for compatibility; its visible
name is Sunny afternoon. Six presets are conditions of one component, not six
independent implementations. `temporal-study` displays all six Standard scenes
and the three sizes together, at a readable 1440 × 1000 logical surface.

| Size | Logical dimensions | Usage |
| --- | --- | --- |
| Compact | 160 × 40 | Narrow ribbon, landscape and time retained |
| Standard | 208 × 48 | Default top anchor |
| Expanded | 400 × 144 | Click detail only, not a permanent ribbon element |

Expanded detail also shows date, season and explicitly simulated rise/set data.
The time uses bundled OFL Rubik; Chinese UI retains Glow Sans. A local ink veil
provides contrast without a live blur or text shadow filter.

## Time and astronomy contract

`TimeBackend.reading` keeps ISO date/time, stable hour/minute strings, phase,
season, weather provenance and `mock`. Sun and moon have separate visibility and
normalized coordinates. The `astronomy` map declares availability, simulation,
sunrise, sunset, moonrise, moonset and phase. Mock events are fixed fixtures,
not location-derived astronomy. Manual phase overrides are explicitly art states.
The independent mock moon window crosses midnight; starry night does not infer
a visible moon just because it is dark.

A real provider must supply independently valid nullable sun/moon event data,
visibility, season convention and weather provenance, including polar/no-event
cases. It must not infer moonrise from sunset. No real provider is added here.

Mock time advances manually in minutes. Sun X is quantized to 15-minute steps;
SVG source and raster size do not change on each minute tick. A future live
provider should publish minute boundaries and clock/timezone/resume events,
never a per-frame astronomy loop. No network request or AI generation occurs.
Finite position/scene transitions stop while hidden, rendering is suspended or
reduced motion is enabled. Static SVGs use Qt Image caching at the requested
physical size. Canvas offers no advantage for these fixed curves and is unused.

## Desktop time hierarchy

Default: only the ribbon time entry. Clock: opt into the large centered time and
date, with weather and media in separate lower side regions. Focus: time/date
with secondary content and Dock hidden. The existing lock preview uses the same
display face, date and a disclosed mock surface; it cannot authenticate or lock.
No automatic idle mode switch is implemented.
