# Blur architecture

Status: researched design. Phase 0 does not implement blur. Phase 1 may add a
small owned-content experiment after its cloud-build gate passes. Native desktop
blur is a later compositor integration, not a property we can enable on every window.

## Ownership and capability

Wayland clients submit their own surfaces; they cannot read arbitrary other-client
surfaces. Wallpaper-only blur behind a preview panel is not equivalent to blur behind
real desktop windows. Do not introduce screen capture, portals or screenshots to
simulate continuous desktop blur. This boundary follows the
[Wayland surface model](https://wayland.freedesktop.org/docs/book/Protocol.html).

The future `BlurBackend` reports native-backdrop, owned-content-GPU and transparency
capabilities separately. A request contains an opaque shell-surface ID, logical
region, corner mask, quality, output scale and content revision. The adapter owns
native handles and invalidates them on surface destruction or compositor reconnect.
No QML component passes raw Wayland pointers.

Selection is capability-driven:

1. Prefer a supported compositor-native backdrop effect for the requested surface.
2. Use a bounded Qt GPU pipeline only for a texture KLDE owns.
3. Use translucency without blur, or an opaque surface when transparency is disabled.

Requests expose unavailable, pending, active and failed state. Missing support must
not produce a black panel, fail startup or silently capture other applications.
An effect is decorative; content and focus remain usable without it.

## Native compositor route

Investigate runtime-advertised standard/staging background-effect protocols first,
then documented compositor-specific alternatives. Protocol support, surface roles,
rounded regions, output scale and policy restrictions need testing on the actual
Ubuntu Kylin compositor. An advertised interface is not proof that a request is
visually honored.

KDE's [blur protocol source](https://github.com/KDE/plasma-wayland-protocols/blob/master/src/protocols/blur.xml)
provides a manager, per-surface blur object, region and commit. It does not give
clients the pixels underneath. A KWin adapter would translate the contract to that
protocol and release objects before their associated surfaces disappear. Any reuse
of protocol XML needs its own upstream license and notices; none is vendored here.

Do not choose the compositor based on blur alone. A native path needs a complete
surface-host story, reconnect behavior and an opaque fallback. Compositor effects
may be disabled by the user's global performance or accessibility policy.

## Owned-content Qt route

Use public Qt Quick texture/effect APIs first. A Phase 1 laboratory can display
an original static swatch next to its filtered version. It must say that the source
is KLDE-owned content, use a fixed bounded area and expose Off/Low/Medium/High.
It is not used behind every shell panel by default.

[ShaderEffectSource](https://doc.qt.io/qt-6.8/qml-qtquick-shadereffectsource.html)
can capture an owned item at a reduced texture size. With `live: false`, content
is refreshed explicitly through `scheduleUpdate()`. Never combine a recursive
capture with live updates: that can continuously dirty the scene. Release the
source and texture resources when the laboratory unloads.

[MultiEffect](https://doc.qt.io/qt-6/qml-qtquick-effects-multieffect.html)
is a suitable first public-API experiment. Its bounded blur settings and optional
source downsampling provide a baseline before maintaining a custom scene-graph
node. Record the selected source resolution, blur preset, pass behavior and memory
use. Avoid changing shader-generating switches during a transition.

If measurements justify a custom pipeline, compare:

| Candidate | Why investigate | Cost / limitation to measure |
| --- | --- | --- |
| Separable Gaussian | predictable quality; horizontal and vertical passes | sampling cost grows with kernel width; cache intermediates |
| Iterative Kawase | small repeated offset kernels | artifacts and pass count vary with radius |
| Dual Kawase | downsample pyramid and upsample reconstruction | extra targets; edge handling and large-radius quality |
| Reduced-resolution filtering | lower bandwidth and smaller targets | thin detail loss; scale transitions and visible seams |

These are engineering candidates, not benchmark conclusions. Radius needs correct
mapping between logical and texture pixels. Pad capture bounds to avoid clipped
edges; clamp sampling and apply corner masks at composition. Do not build an
unbounded full-output pyramid for a small widget.

[ShaderEffect](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html)
consumes build-time shader packs in Qt 6. A future custom shader should use Qt
Shader Tools and CMake resource embedding, with the same shader artifact tested
on supported backends. Software scene-graph rendering is an explicit fallback.
Do not infer GPU effect support merely from the presence of a QML import.

Do not use private QRhi or scene-graph internals in Phase 1. If public APIs become
insufficient, a separate ADR must identify the exact API/version boundary,
maintenance burden, alternatives and fallback before such a dependency is added.

## Caching, damage and lifecycle

Cache keys include source revision, padded region, texture size, scale, quality and
theme-dependent mask. Content changes invalidate capture and filtered output;
quality changes invalidate filtering; moving an unchanged owned source should not
recompute its texture. Handle output-scale changes as size changes. Native blur
damage scheduling belongs to the compositor; KLDE must not request redundant frames.

Coalesce several invalidations into one scene-graph update. No timer drives the
pipeline. A static scene must stop submitting frames after pending work settles.
Hidden views unload effect objects. Screen-off, suspend, output loss and minimized
preview state suspend effect work, with one refresh on resume. The future session
adapter supplies real screen/output lifecycle events; it is absent in Phase 0.

Cap scratch memory and texture dimensions; account for device-pixel ratio. A
logical 512×512 RGBA8 texture at scale 2 uses about 4 MiB before intermediate
targets. This is a size calculation, not a measured allocation or performance result.
Set budgets from measured hardware behavior, and fall back on allocation failure.

## User policy and acceptance

The eventual settings model exposes Blur Off/Low/Medium/High, Transparency Off/On,
Shadows Off/On, and Animations Reduced/Normal/Expressive. Tokens carry intent;
adapters map it to supported operations. Reduced motion does not imply changing
contrast or forcing transparency. Opaque mode is reviewed visually as a full theme.

Acceptance requires capability/fallback unit tests, cache-invalidation tests,
headless correctness captures, and idle frame-count checks after transitions.
Screen-off and reconnect tests arrive with those real adapters. Compare actual
Intel UHD 620 GPU activity, memory and frame times separately using the
[performance protocol](../development/performance.md). llvmpipe results do not
establish real GPU efficiency. No performance result is claimed by this document.
