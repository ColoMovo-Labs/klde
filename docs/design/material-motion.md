# Material and motion study

Status: mock-first study for a possible 0.2 visual freeze. The 0.1 layout, colour
roles and material tiers stay the default; the production controls now consume
the restrained motion tokens below, while the new material tiers remain limited
to `--view material-study`.

The fusion gives each influence one job so the three do not blur together:

| Influence | Owns | Does not own |
| --- | --- | --- |
| Material Expressive | spring motion, shape morphing, emphasis, Monet colour roles | material translucency |
| Fluent (WinUI 3) | material tiers, elevation rim, small inner radii, double focus ring | motion curves |
| Glass | edge refraction and sheen on a few floating controls | panels, menus, text-heavy surfaces |

These are principles, not copies. No Segoe, SF or vendor icon sets are used,
and the study labels its tiers as references rather than product names.

## Motion tokens

`Tokens.spring(dampingRatio, stiffness)` evaluates the damped unit-mass spring
response and bakes it into a 10-segment Bezier spline (the most QEasingCurve can hold safely) that settles within 0.08%.
Durations stay finite, reduced motion collapses them to zero and the idle audit
sees a definite end. The values follow the Material Expressive physics schemes:

| Token | Standard (motion 1) | Expressive (motion 2) |
| --- | --- | --- |
| `springSpatialFast` | 0.9 / 1400 | 0.72 / 1500 |
| `springSpatialMicro` | 0.94 / 2600 | 0.80 / 2200 |
| `springHover` | 0.96 / 1500 | 0.88 / 1200 |
| `springPopup` | 0.94 / 650 | 0.82 / 480 |
| `springSpatial` | 0.9 / 700 | 0.8 / 380 |
| `springSpatialSlow` | 0.9 / 300 | 0.8 / 200 |
| `springEffects*` | 1.0 / 3800, 1600, 800 | same |

Spatial springs move and resize and may overshoot; effect springs drive colour
and opacity and never do. Motion level 3 (Fast) plays the standard scheme at 0.8×.

## Material tiers

`Surface.material` selects `classic` (0.1), `mica`, `acrylic` or `glass`. Each
tier is one bounded pipeline: a non-live capture of the owned wallpaper, a public
MultiEffect blur, then `qml/effects/material.frag` for rounded coverage,
refraction, saturation, tint, static grain and a light-facing 1 px rim.

| Tier | Use | Blur | Tint | Extras |
| --- | --- | --- | --- | --- |
| Mica | long-lived panels | heavy, ⅛ resolution | 70–80% surface | muted saturation, faint rim, no shadow |
| Acrylic | menus, flyouts | strong, ¼ resolution | ~60% elevated | grain, elevation rim, key shadow |
| Glass | dock, capsules | light, ½ resolution | 12–20% | 16 px lens, dispersion, sheen, press response |

Without GPU effects, with transparency off or blur Off, every tier draws an
opaque fill and border. Glass refracts only KLDE-owned wallpaper. Over real
application windows it must fall back to Acrylic until a compositor backdrop
adapter exists; see [blur architecture](../architecture/blur.md).

## Default shell mapping

The approved shell keeps its existing composition while using the tiers as
details: top-ribbon groups use Mica, popups and ChoiceBox menus use Acrylic, and
the Dock uses Glass. The Temporal Capsule keeps its expressive landscape artwork
and remains the visual anchor rather than becoming a generic glass panel.

## Acceptance

The CircleCI visual matrix captures the study in light, dark, English 1440×900
and the kemono wallpaper on the llvmpipe GPU path. Owner review compares the two
columns before any tier or spring replaces 0.1 tokens in the shell. Real GPU cost
on Intel UHD 620-class hardware has not been measured.
