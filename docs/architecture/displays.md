# Displays and per-output surfaces

`Shell.screens` (`ScreenModel`) has one row per `QScreen`. It follows
`QGuiApplication::screenAdded`, `screenRemoved` and `primaryScreenChanged`
with row inserts, removals and `dataChanged`, so `Main.qml`'s `Instantiator`s
create or destroy only the surfaces of the output that changed.

- Wallpaper: one layer-shell surface on every output, sized to that output.
- Top bar and dock: created for every output but mapped only on the primary
  output, unless Settings > Displays enables `ribbon.allScreens` or
  `dock.allScreens`. When the primary output changes they move with it.
- Popups: one popup host. Panels opened from a top bar or dock open on that
  surface's output; the host is unmapped, retargeted with
  `Shell.surface.setOutput()` and mapped again when the output differs.
  Keyboard shortcuts use the compositor's active output.
- Each QWindow is bound to its own QScreen, so each output renders at its own
  device pixel ratio; all layout is in logical pixels.

The Displays page is read-only. It lists name, model, mode, refresh rate,
scale and position for each output. Changing resolution, scale, arrangement or
the primary output needs the privileged `kde_output_management_v2` protocol,
which owoDE does not use yet (libkscreen wraps it); the page says so and points
to KDE Display Configuration.

`tools/multi-output-smoke.sh` runs the native shell in a nested KWin with
`--output-count 2` and checks the Wayland log: two wallpaper surfaces on two
different outputs, and the top bar and dock together on one of them. The CNB
Fedora 44 pipeline and CircleCI's native jobs run it. The Debian cloud workspace
cannot: its LayerShellQt (6.3) is older than the 6.6 the native surfaces need.
