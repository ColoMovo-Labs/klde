# Visual System Lab workflow

This phase is intentionally mock first. It validates behavior and composition before
Linux service bindings freeze the UI. CircleCI builds and tests; local work remains
editing, review, commits and optional formatting/asset preparation.

## Explore a cloud-built installation

```sh
klde-shell --locale zh_CN --voice cute --density dense --wallpaper abstract --ambient
klde-shell --scenario hybrid-gpu-laptop --view power-scenes
klde-shell --scenario critical-battery --view notifications
klde-shell --dev-tools
klde-shell --size 1080x1920 --view quick-settings
```

`--size` is logical pixels. Set `QT_SCALE_FACTOR=2` with `--size 1440x900` for the
2880×1800 physical capture. Unsupported scenario IDs, densities, wallpapers and
malformed sizes fail explicitly. The cloud capture mode also fails on QML warnings,
missing images or continuous rendering after settling.

Ctrl+Alt+M opens the opt-in Mock Lab. Change scenarios, locale, voice, appearance,
accent, wallpaper, effects, density, power scene and individual mock readings.
Selecting a scenario resets all fixtures and experimental weather consent. Values
remain in RAM; no preferences file, hardware policy or system locale is changed.
The mock clock advances only on a requested state change, not a repaint timer.

## Product surfaces

The ribbon contains three independently wrapping sections. Registry IDs, section,
order, visibility and priority are data, not a monolithic panel. Comfortable hides
low-priority modules; Balanced and Dense expose more information. Expanded status
retains detailed labels. Its customization page supports visibility, section,
reorder buttons, margin and spacing. Top placement is the current experiment;
height follows shared density. Persistence, drag gestures and alternate placement
are not implemented.

F2 opens compact Quick Settings; its expansion adds microphone/output, Language
& Input, notifications and density. Power Scenes provide visual policy and validated
hardware-policy previews. Capability fixtures hide battery, microphone, brightness,
sensors and unsupported GPU choices appropriately. Media, notifications and input
share the same central state contract as the ribbon.

Notification tabs show synthetic profile/activity, dismissible notifications and
weather. No user account or message from supplied references is included. Candidate
selection and Simplified/Traditional are an owned visual sample, never a native IME
surface or cross-application text injection. Fcitx remains the future engine.
Ambient workspace is optional clock/weather/media composition, not a secure lock.
Wallpaper-driven accent uses four sample palettes; actual color extraction is future
work. Four original vector wallpaper studies are included.

## Keyboard scope

Super tap and Super+Space open the launcher only when the host delivers those keys
to this ordinary application window. Ctrl+Alt+Space remains available. Super+1…5
changes preview workspace; Super+Shift+1…5 moves the mock terminal. Bindings 6…9
are reserved and rejected because this fixture has five workspaces. Super+V toggles
mock floating, Super+Q closes preview application context, Super+N toggles the
notification center, Super+M toggles media state, Super+Shift+S opens a session-only
scratchpad. No global shortcut service or compositor behavior is claimed.

## Cloud evidence

`tools/smoke-test.sh` covers offscreen, headless Weston/Wayland, XCB, llvmpipe and
individual panels. `tools/visual-matrix.py` adds all eight locale/voice/theme
combinations, Standard/Cute edge cases, nine weather conditions, four wallpapers
and six display configurations. PNGs and per-case logs live in CircleCI artifacts;
`matrix/manifest.json` identifies source revision, input state, logical/physical
size, scale and exit code. This is rendering correctness and regression evidence,
not Intel GPU speed, battery life, input latency or accessibility sign-off.

Selected canonical captures live under `docs/previews` with exact rendering
revision and pipeline. Manual inspection must check composition, clipping, focus,
CJK punctuation, light/dark contrast and clear state indication. A green build
alone cannot establish visual quality.

## Frozen capture evidence

Rendering source `752af8c8f36b9f6c8272188831e51876c8192b11` passed all eight
CircleCI jobs in [pipeline 38](https://app.circleci.com/pipelines/circleci/3oxaeukVqAvAfF4HxntS1j/9f38edc2-e2b3-4a5a-b510-656e0f838973/38/details?workflowId=6f262d05-ad85-42b2-b335-4c19c5d39b24).
Its 72 matrix cases completed successfully; individual panels and Wayland/XCB
interaction suites also passed. The Debian runtime job installed, exercised and
removed the package in a clean Ubuntu container.

[Seven selected captures](../previews/README.md) were inspected for composition,
text and clipping, including the Dense full-HD ribbon's single-row fit. The six
size configurations were reviewed during this pass. Narrow layouts wrap; long
control pages deliberately scroll inside bounded panels. This is an engineering
visual review, not owner design acceptance or assistive-technology verification.
The rendering revision stays pinned when later documentation commits are added.

## Mock phase exit review

Do not infer readiness for real system integration from this implementation.

- [ ] Owner accepts the final-ish shape language, density and reference fidelity.
- [ ] Inspect canonical light/Chinese/Standard and Cute, dark/Chinese/Cute,
      Dense ribbon, Quick Settings, notification center and Language & Input.
- [ ] Inspect every size, HiDPI scaling and long/translatable text in CI artifacts.
- [ ] Review keyboard flows with the actual host compositor and assistive tools.
- [ ] Validate all hardware absence/error states and tone-locked critical messages.
- [ ] Profile representative hardware for frame time, idle CPU/GPU, blur memory
      and wakeups; software CI cannot close this item.
- [ ] Accept consistent motion, opaque/translucent/blur fallback and typography.

Real audio/network/power, compositor surfaces, global shortcuts, secure session
control, native candidates and distribution engineering remain later work.
