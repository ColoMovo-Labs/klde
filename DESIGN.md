# Design

Status: Phase 1 implements the seed token system and mock shell components.
Actual cloud-rendered captures are in the [prototype guide](docs/development/phase-1.md).

## An independent identity

KLDE takes the bright, soft atmosphere of the 2020–2021 Kylin era as a starting
emotion, then develops its own geometry and interaction. The idle desktop should
be calm and spacious; a user's action gives surfaces a brief, expressive response.
Material Expressive contributes principles of shape variation, emphasis and motion,
not components copied pixel for pixel. macOS spacing, GNOME restraint and mobile
composition are references, not templates.

Kemono influence belongs in subtle organic silhouettes, an optional mascot,
friendly icons and original wallpaper. A serious application window should not
need ears or paws to look like KLDE. Novelty decoration is optional and never
competes with readable content or state.

## Composition

A compact centered floating dock anchors application access. Quick settings opens
as a separate upper-right surface; the launcher is a centered, search-first view
with immediate text focus. A round weather widget demonstrates a built-in widget
contract. Workspace indicators communicate both position and layout mode.
No permanent full-width bottom panel is required.

The future workspace language uses four neutral modes: Floating, Classic Tiling,
Scrolling Tiling and Mixed. The shell presents the policy and effective state;
KWin-specific scripts, tile trees or effects remain behind the backend boundary.
“Classic” and “Scrolling” describe interaction models, not clones of Hyprland or
niri. A KWin decoration/effect may supply compositor cooperation, but the KLDE
surface must remain complete when that capability is absent.

The snow-mountain preview establishes left circular weather, centered workspace
pill, right controls and a compact bottom dock. The supplied colorful screenshot
adds a concrete emphasis reference: saturated blue/purple, thick filled sliders,
circular active icons and soft tinted floating surfaces. KLDE implements these
principles with original assets and component geometry. No reference wallpaper,
application logo or application window is copied. See the
[reference study](docs/design/reference-study.md). Captures identify real preview revisions.

Shape hierarchy has a purpose: the weather circle feels ambient, active workspace
pills expand beside compact inactive chips, primary scene cards have a strong
soft silhouette, and secondary controls use smaller corners. A colorful accent
must not flatten every component into an identical rounded rectangle.

Surface hierarchy follows purpose: wallpaper, low-emphasis widget, active panel,
focused control. Corners can vary between an outer panel and an emphasized
control, while spacing and alignment stay systematic. App windows shown in a
future concept must be distinguished from real host windows.

## Token contract

Phase 0 seeds one QML singleton as the source of truth. Phase 1 components refer to
semantic tokens rather than repeating numeric layout values. Add a named metric
when geometry has a repeated purpose; do not invent a token for every local ratio.
The following are seed values to evaluate visually, not tested accessibility claims.

| Category | Required tokens / initial direction |
| --- | --- |
| Colors | background, surface, surfaceContainer, surfaceElevated, primary, secondary, tertiary, error, outline, textPrimary, textSecondary, textDisabled |
| Transparency | surfaceOpacityLow 0.72, surfaceOpacityMedium 0.88, surfaceOpacityHigh 0.97; opaque mode uses 1.0 |
| Radii | radiusXS 4, radiusS 8, radiusM 14, radiusL 22, radiusXL 32, radiusPill (half the smaller dimension) |
| Spacing | space1, space2, space3, space4, space6, space8, space12, space16, space24, space32, in logical pixels |
| Typography | display 48, headline 30, title 22, body 16, label 14, caption 12; all multiplied by text scale |
| Motion | motionFast 120 ms, motionNormal 220 ms, motionSlow 360 ms |
| Easing | emphasized, emphasizedDecelerate, emphasizedAccelerate, standard, bounded spring-like approximation |
| Elevation | flat, low, medium, high; map to border/tone first and optional cached shadow |
| Blur | blurNone, blurLow, blurMedium, blurHigh; policy presets, not compositor-independent pixel guarantees |
| Density and icons | shared iconS/M/L, dockIcon, densityScale and component metrics |

The revised light seed uses pale blue surfaces, a saturated indigo primary,
lilac secondary and warm apricot tertiary. Thick value bars, circular active
icon discs, selected scene surfaces and finite pressed-shape transitions make
emphasis visible beyond corner rounding. Dark mode needs its own
surface and text roles, not a global color inversion. Evaluate contrast on both
opaque and translucent backgrounds before accepting a palette.

Use distribution-provided Noto Sans CJK SC for Chinese and sans serif for English,
with separately adjusted Chinese label/caption density and user scaling. See
[CJK typography](docs/design/typography-cjk.md) and
[voice and microcopy](docs/design/voice-and-microcopy.md). Locale and voice are
independent; Cute changes selected friendly messages and never precise security,
privacy, legal or destructive text.

Use a distribution-provided sans serif with CJK fallback. Do not bundle a font
without reviewing its license. Text uses semantic font tokens and user scaling;
layouts must eventually accommodate longer translations, RTL content and 200%
text size. Current bilingual captures and glyph checks are narrower evidence;
comprehensive scaling, RTL and screen-reader acceptance is still pending.
Phase 1 maps the seed roles into shell components and the Qt Controls palette,
with light/dark SVG ink variants. Theme-pack loading, wallpaper-derived accents
and comprehensive visual accessibility acceptance remain future work.

## Motion and effects

Use short finite transitions for invocation, selection, expansion and dismissal.
The spring approximation must settle; overshoot is inappropriate for text or
precision sliders. Never animate a permanently hidden view. Reduced motion removes
translation/overshoot and permits immediate state changes or a brief fade.

Opaque surfaces are a first-class design. Transparency must not reduce legibility.
Native compositor blur is preferred when supported; owned-content GPU blur stays
bounded and cached. See [blur architecture](docs/architecture/blur.md). No panel
may require expensive blur to look complete.

Blur is enabled in normal default policy, including Performance and Power Saver
at Low quality. In this standalone preview the dock, widget and panels can filter
only the KLDE-owned wallpaper; this is not native blur behind other applications.
Unsupported rendering and an explicit user Off choice retain a complete opaque
appearance. [Power Scenes](docs/architecture/power-scenes.md) pair the selected
system intent with editable theme, effect and motion choices. Scene cards show
an icon, description and customization state rather than a bare dropdown.

## Accessibility and input

Keyboard focus is always visible and independent of color. Launcher search accepts
typing immediately, arrows select, Enter activates, and Escape dismisses and returns
focus to the invoker. Sliders and toggles support keyboard operation and accessible
names. State uses text, shape or an indicator in addition to hue. Hover is never
the only way to expose an essential action.

Plan desktop targets of at least 40 logical pixels, larger touch targets where
appropriate, no clipped scaled text, and checks against 4.5:1 normal-text and 3:1
large-text/control contrast targets. These are design acceptance goals; actual
contrast and screen-reader behavior must be verified on implemented components.

## Theme evolution

Light, dark and user-selected accents come first. Wallpaper-derived accents follow
only after contrast correction, deterministic extraction and an override are
specified. Theme packs are data with validated bounds; arbitrary QML execution
must not be silently accepted as a color theme. Their file format and loader are
future work.

The preview offers user-selected accent presets; they remain session choices.
Wallpaper extraction, arbitrary theme packs, persistent settings and complete
contrast/accessibility acceptance are separate work.

## Temporal axis direction

The current product principle is **time as center, order as atmosphere**. KLDE is
still a provisional codename. Chinese contemporary influence starts with central
axis, hierarchy, rhythm, restraint and spacing; ornamental motifs and paid visual
packs are future optional asset layers. There is no commerce or donation prompt
in this milestone.

The [grouped top ribbon](docs/design/top-ribbon-layout.md) and
[Temporal Capsule](docs/design/temporal-capsule.md) organize time and system state.
[Wallpaper depth](docs/design/wallpaper-depth.md) is an optional precomputation and
cache contract. The prototype's pre-authored studies do not run segmentation.
Display-clock typography is separate from normal UI typography. Default mode keeps time in the ribbon; Clock/Focus explicitly enable the large
clock. [Night roles](docs/design/night-palette.md) have dedicated resources and
colors. All surfaces use shared
shape, group spacing, motion and color tokens. Wayland is primary; X11 testing is
a compatibility check.
