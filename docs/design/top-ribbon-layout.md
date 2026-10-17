# Screen axis and ribbon density

The ribbon has three independent zones. Left holds launcher/application, date
and workspaces. Center holds the landscape. Right groups monitoring, connectivity
and session controls. Outer margins are symmetric and each zone uses its natural
painted width, so a short left zone does not allocate invisible blank panels.

For screen width W, margin M and capsule width C, the ribbon has width W−2M.
Its capsule X is `(W−2M−C)/2`; adding M gives screen left `(W−C)/2`, hence the
center is exactly W/2. Side lanes end/start one group gap before/after the central
reserved interval. Their contents may wrap vertically inside those lanes; they
cannot push the center. Every group is vertically centered in one row band.

## Degradation in logical pixels

Thresholds apply to the available ribbon width, not physical screenshot pixels.
At 2× scaling a 1440 × 900 logical surface is a 2880 × 1800 capture.

| Available width | Behavior |
| --- | --- |
| 1500+ | Standard landscape; full short values and normal 2×2 telemetry |
| 1160–1499 | Compress telemetry cells; omit redundant text and optional mic/mood entries |
| 880–1159 | Compact landscape; fold date/input/Bluetooth and monitoring into existing menus |
| Under 880 | Keep the center on the first band; move two side lanes underneath |

The existing system dashboard retains all monitoring values; Quick Settings and
Input/notification panels retain the folded functions. No service/registry state
is disabled by visual folding. Warning markers and accessible names survive.
Custom registry spacing can cause additional side-lane wrapping without moving
the center. The full-ribbon visibility preference remains available.

Spacing tokens use 4 px group padding, 4/8 px content gaps, 12/16 px module gaps
and 24 px separation for major desktop regions. Controls share a 40 px row (44
in Comfortable), group height 48/52, and centers rather than arbitrary top edges.
The telemetry enclosure has no redundant individual capsule backgrounds. Its
four stable IDs are CPU, RAM, temperature and battery; unavailable battery is
omitted, absent sensors show an em dash. Values are explicitly Mock in tooltips
and the existing detail dashboard.

## Verification

Cloud Qt Quick tests exercise 640/1024/1366/1600/1920/2560/3440 logical widths,
three densities, exact center and outer-edge constraints, plus side-lane collision
bounds. The visual matrix captures 1366×768, 1600×900, 1920×1080 and 2560×1440,
alongside prior HiDPI/portrait/ultrawide cases. Native Qt ribbon crops retain their
original resolution. Geometric success must be accompanied by actual PNG review;
it does not establish visual quality by itself.
