# Design

Status: direction and token contract for Phase 1; not a screenshot of implemented UI.

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

Suggested light seed: cool ivory background, white elevated surfaces, deep blue-green
primary, muted lilac secondary and warm apricot tertiary. Dark mode needs its own
surface and text roles, not a global color inversion. Evaluate contrast on both
opaque and translucent backgrounds before accepting a palette.

Use a distribution-provided sans serif with CJK fallback. Do not bundle a font
without reviewing its license. Text uses semantic font tokens and user scaling;
layouts accommodate longer translations, RTL content, and 200% text size.
Phase 0 uses ordinary Qt Controls and the seed singleton on a minimal window.
The full component/theme system and visual accessibility validation remain future work.

## Motion and effects

Use short finite transitions for invocation, selection, expansion and dismissal.
The spring approximation must settle; overshoot is inappropriate for text or
precision sliders. Never animate a permanently hidden view. Reduced motion removes
translation/overshoot and permits immediate state changes or a brief fade.

Opaque surfaces are a first-class design. Transparency must not reduce legibility.
Native compositor blur is preferred when supported; owned-content GPU blur stays
bounded and cached. See [blur architecture](docs/architecture/blur.md). No panel
may require expensive blur to look complete.

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
