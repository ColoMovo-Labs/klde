# owoDE Real Session 0.2: native Wayland shell surfaces

Real Session 0.1 is complete as a runtime bring-up milestone. The owner’s
Fedora 44 report verified KWin 6.7.5 nested inside niri, a dedicated nested
Wayland socket, the native `klde-shell`, a genuine Qt 6 Wayland client and
basic focus interaction while niri remained operational. The run used an
Xwayland-hosted nested KWin viewport because pure Wayland-on-Wayland nesting
reported a missing `wp_single_pixel_buffer_manager_v1` protocol. That is a
runtime compatibility finding to keep in the log, not a reason to modify niri
or patch KWin.

The next implementation boundary is to turn the existing ordinary Qt
`ApplicationWindow` composition into three independent LayerShellQt-backed
surfaces without redesigning the approved UI:

| Surface | Intended layer | Intended anchors | Input contract |
| --- | --- | --- | --- |
| wallpaper | background | all edges | transparent for input; never focusable |
| top ribbon + Temporal Capsule | top | top / left / right | pointer input only where controls exist; no keyboard focus |
| dock | top | bottom / left / right during the first slice | pointer input on dock; no keyboard focus |

`src/platform/wayland/NativeSurfaceController.*` is the optional adapter. It
uses the public LayerShellQt interface when CMake finds
`LayerShellQt::Interface`; ordinary preview and Visual Lab continue to build
when the package is absent. `klde-shell --native-shell-surfaces` is explicit so
the fallback path cannot be mistaken for a desktop shell.

## Target-host smoke test

When Fedora supplies LayerShellQt development files, CMake also builds
`klde-layer-shell-smoke`. Run one role at a time inside the already-working
isolated KWin session:

```sh
QT_QPA_PLATFORM=wayland build/ci/bin/klde-layer-shell-smoke --role wallpaper
QT_QPA_PLATFORM=wayland build/ci/bin/klde-layer-shell-smoke --role ribbon
QT_QPA_PLATFORM=wayland build/ci/bin/klde-layer-shell-smoke --role dock
```

The helper prints the requested role, Wayland QPA and mapped lifetime. KWin
logs and compositor inspection must still be collected for the actual protocol
role; a process exit or a screenshot alone is insufficient.

The full launcher keeps the proven, isolated path and supports both modes:

```sh
# Compatibility preview mode (default)
OWODE_MODE=preview OWODE_APP='your-qt-wayland-app' \
  bash tools/run-lomode-session.sh

# Native surface mode; fails safely if LayerShellQt is not available
OWODE_MODE=native OWODE_APP='your-qt-wayland-app' \
  bash tools/run-lomode-session.sh
```

Each invocation chooses a unique socket name and cleans up only its own KWin,
shell and optional application PIDs. It does not remove a pre-existing socket.
The historical `wayland-2` name and the reported PIDs 38175 / 41961 are
evidence labels only, never configuration.

The owner reported that setting `XCURSOR_THEME=Bibata-Modern-Classic` and
`XCURSOR_SIZE=24` improved the oversized cursor in the nested test. The runner
scopes those defaults to the nested shell/client processes; this is a
reproducible observation, not a proven compositor diagnosis, and it does not
change the host niri cursor.

## Acceptance matrix

| Requirement | Current status |
| --- | --- |
| Nested KWin 6.7.5 starts beside niri | verified by owner report |
| Real Qt client and owoDE preview coexist | verified by owner report |
| LayerShellQt smoke test source and explicit mode | implemented; Fedora execution pending |
| Wallpaper background role | source adapter implemented; protocol/log evidence pending |
| Ribbon anchoring and exclusive zone | source adapter implemented; KWin verification pending |
| Dock anchoring and pointer region | source adapter implemented; input verification pending |
| Maximization, focus and popup placement | pending target-host evidence |
| Mock/Visual Lab regression path | preserved in CircleCI configuration |

No LingmoOS application migration, compositor rewrite or advanced tiling work is
part of this milestone.
