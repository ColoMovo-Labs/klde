# Power Scenes

Power Scenes coordinate two separate policies: a requested system profile and
the shell's visual preferences. Selecting a scene is not proof that hardware
accepted every operation. The current prototype uses mock system state and
real visual preferences inside its own window.

## Contract and defaults

`PowerSceneController` exposes stable IDs, scene name, icon, description,
customization state, supported controls and current visual policy. The three
built-in scenes can be edited and reset for the current preview session.
Persistent profiles and user-created scenes need a versioned settings schema later.

| Scene | System intent | Default visual intent |
| --- | --- | --- |
| Performance | performance profile where supported | blur on, Low quality; normal motion and shadows |
| Balanced | balanced profile where supported | blur on, Medium quality; normal motion and shadows |
| Power Saver | power-saver profile where supported | blur on, Low quality; reduced motion and lighter effects |

Blur remains enabled in all default scenes. A user may explicitly disable it;
choosing lower cost must not automatically remove KLDE's visual identity.
Theme (auto/light/dark), blur quality, transparency, shadows and motion are
independent choices. Auto currently follows the preview's initial appearance;
an actual system appearance subscription comes with the settings backend.

Quick settings presents a primary scene card with icon, description, selected
state, customization indicator and an advanced customization entry. Unsupported
hardware options do not appear as working controls. A reset restores that scene,
without changing another scene's customization.

## System integration boundary

The first consumer uses `SystemBackend`'s small mock power-profile contract.
Real integration splits into `PowerBackend`, `GraphicsBackend`, `DisplayBackend`
and `EffectsBackend` when those adapters acquire actual independent lifetimes:

- Power: asynchronous power-profiles-daemon or documented platform API; report
  advertised profiles, holds, pending requests, degradation and confirmed state.
- Graphics: discover GPU topology and vendor capabilities. Do not infer dGPU
  switching support from a device's presence or write generic vendor commands.
- Display: negotiate supported modes per output; account for scaling and
  multi-monitor restrictions. A requested refresh rate can be rejected.
- Effects: retain user preferences separately from effective supported rendering
  strategy; an unavailable GPU/native effect uses the documented fallback.

Brightness, CPU governor/frequency, GPU state and refresh policy are optional
capabilities. No CPU-frequency, dGPU or refresh control is exposed in this mock
preview. A desktop without a battery still has meaningful scene/effect choices.

No QML writes sysfs, runs commands or obtains privilege. If standard services
cannot perform an authorized operation, propose a small allowlisted helper and
Polkit policy in a separate ADR. Never grant a generic command execution helper.
Apply operations asynchronously, reconcile confirmed state, and surface partial
failure rather than promising an unsafe cross-service transaction or rollback.

## Acceptance

Cloud tests cover preset selection, per-scene edits/reset, invalid requests,
default blur retention and the selected effective blur policy. Rendering captures
cover the scene card and advanced controls. These tests do not establish CPU
governor, GPU or display-mode changes on real hardware. Hardware and power
acceptance uses [the performance protocol](../development/performance.md).
