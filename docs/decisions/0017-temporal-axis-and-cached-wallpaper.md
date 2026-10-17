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

## Visual correction amendment (2026-10-17)

The first icon-and-time form did not meet the landscape requirement. The amended
presentation has three landscape sizes and six finite states. Rubik weight 800
replaces Comfortaa as the selected clock face, with its original OFL notice.
Default desktop no longer paints a second clock; Clock and Focus are opt-in.
Dedicated night resources replace global day-wallpaper dimming. Independent
provider contracts and mock boundaries are unchanged. Details and actual cloud
evidence: [Temporal 2.0](../development/temporal-v2.md).
