# 0017: Temporal axis and cached wallpaper effects

## Context

The independent pill ribbon was fragmented and the ambient clock reused body
font proportions. The product now prioritizes spatial order, time, lower-power
hardware and a future rebrand while staying in its mock design phase.

## Decision

Pin the Temporal Capsule to the horizontal axis, group status semantically and
compose telemetry into a two-column grid. Add display-only Comfortaa Bold tokens.
Separate requested wallpaper preferences from effective cached-image policy and
provide typed time/telemetry/wallpaper/optional Android contracts. Wayland is the
primary product path. Branding display identity remains replaceable.

## Consequences

There is less arbitrary center-lane customization. Narrow side lanes wrap below
the anchor. Resource fixtures can prove composition/fallback before a segmentation
worker exists, but cannot prove extraction quality, real locking or GPU/power
performance. Cloud builds and screenshot inspection are still required.

## Alternatives considered

Equal-weight metric pills retained noise. Globally replacing the UI font weakened
normal text. Proprietary display fonts carried avoidable licensing constraints.
Always-running segmentation, per-frame blur and an immediate compositor fork do
not fit the current phase or performance goals. Decorative cultural skins and
commerce remain future independent asset layers.
