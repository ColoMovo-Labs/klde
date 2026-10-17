# Time as center, order as atmosphere

The provisional KLDE shell takes spatial order, hierarchy and restraint from a
Chinese contemporary design direction. This pass adds no traditional ornaments,
festival palette or cultural motifs. The core stays globally usable.

## Composition

```text
[left: context · date · workspaces]  [Temporal Capsule]  [telemetry · connectivity · session]
```

The Temporal Capsule owns the exact horizontal center of the viewport, regardless
of left/right content width. Outer margins are symmetric. Side groups may have
different widths; they share a height rhythm, surface, baseline and spacing scale.
They wrap within their own lanes rather than shifting the temporal anchor. Below
1000 logical pixels the two side lanes move below the center capsule. Long panels
start below the full ribbon, not on top of its wrapped rows.

“Group tight, groups apart”: 2 px internal gaps, 4 px group padding and 12/16 px
inter-group gaps depending on density. The existing spacing control adds space
above that minimum. These values are shared tokens, not individual component rules.
Comfortable/Balanced/Dense still alter density and low-priority visibility.

## Semantic groups

| Group | Contents / behavior |
| --- | --- |
| Context | Launcher and current application; overview/weather remain optional |
| Date | Localized date and weekday; future solar terms are not implemented |
| Workspace | Floating/tiling/mixed mock workspace selection |
| Temporal | Pinned center; cannot be moved or individually hidden |
| Telemetry | CPU/memory/temperature/battery in one composite two-column grid |
| Connectivity | Wi-Fi/Bluetooth/audio/microphone; shared enclosing surface |
| Session | Input/notifications/settings/power; shared enclosing surface |
| Extras | Optional power-scene module |

CPU/memory/temperature/battery retain stable registry IDs and individual actions,
but do not each own a capsule background. Cells remain keyboard focusable, have
accessible names, and retain warning/critical text markers. Missing battery is
omitted; absent sensors show an unavailable value. Short-lived metric changes do
not resize or reorder groups.

The registry reserves Center for time. Other modules can move between Left and
Right; ordering controls reorder within a semantic group. This intentionally
replaces the earlier unrestricted three-lane pill experiment. Full ribbon hiding
remains an explicit preference. Existing 20 module IDs are preserved.

## Acceptance

The earlier seven baselines remain immutable, revision-labelled references.
New source must receive CircleCI rendering and human image inspection at six
sizes, both languages, voices and themes before selecting replacement baselines.
Source edits and formatter success alone do not establish visual acceptance.
