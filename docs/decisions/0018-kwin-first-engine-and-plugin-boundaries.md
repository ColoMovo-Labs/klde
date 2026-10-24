# ADR 0018: KWin-first engine and plugin boundaries

Status: accepted direction; implementation deferred until an adapter consumer exists.

## Context

KLDE and LingmoOS both use KWin-family compositor foundations. The previous
architecture treated KWin, wlroots and other compositor paths as equal future
candidates, even though KWin plugins, window rules, effects, decorations and
session components are now the most compatible research path. Lingmo's KWin
lineage and upstream KWin 6 are not ABI-identical, and Cutefish plugins target
specific KWin 6/KDecoration3 builds.

## Decision

Make KWin the first `WindowManagerBackend` engine candidate. Keep the backend
contract engine-neutral, but add a KWin adapter with explicit engine-family,
API-version, Qt/KF-version and protocol capability probing.

Prototype workspace policies as KWin scripts/KPackages. Use KWin's public tile
and window properties for Classic Tiling and Mixed mode. Keep Scrolling Tiling's
layout planner in KLDE and map it only to supported KWin operations. Add a C++
KWin effect or KDecoration3 plugin only when a script/API cannot provide the
required behavior, and rebuild it for the exact target KWin ABI.

Treat LingmoOS and Cutefish sources as audited references or narrowly adapted
components. Never copy global `kwinrc` defaults, branding, private KWin types or
security-sensitive lock-screen code without a separate provenance and security
review.

## Consequences

KWin integration receives the earliest engineering attention and can reuse the
shared compositor foundation without coupling QML to KWin objects. The adapter
must carry more compatibility metadata and CI must test exact engine profiles.
A KWin-family profile may expose fewer capabilities than upstream KWin 6.
Scrolling Tiling and secure locking remain conditional rather than promised by
mock state.

## Alternatives considered

- **New compositor:** deferred; only revisit if a measured KWin capability blocker
  survives an adapter prototype.
- **Blind LingmoOS fork:** rejected because Lingmo's deepin-kwin lineage, Qt/KF
  stack and plugin ABI are not the same as every upstream KWin 6 target.
- **Direct QML calls into KWin:** rejected; UI keeps using opaque backend IDs and
  request/confirmation signals.
- **Treating ext-session-lock-v1 as universal:** rejected; protocol support must
  be detected alongside KWin's internal lock-screen path.
