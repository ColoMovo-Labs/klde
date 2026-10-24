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
| wallpaper | background | all edges; exclusive zone -1 | transparent for input; never focusable |
| top ribbon + Temporal Capsule | top | top / left / right | rounded input masks around visible groups; no keyboard focus |
| dock | top | bottom / left / right | rounded input mask around dock; no keyboard focus |
| popup host | overlay | all edges; exclusive zone -1 | mapped only while a dismissible panel is open; temporary keyboard focus |

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
  bash tools/run-owode-session.sh

# Native surface mode; fails safely if LayerShellQt is not available
OWODE_MODE=native OWODE_APP='your-qt-wayland-app' \
  bash tools/run-owode-session.sh
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
| LayerShellQt smoke test source and explicit mode | implemented; uses the production controller |
| Wallpaper background role | source uses background / all anchors / zone -1; KWin protocol validation required |
| Ribbon anchoring and exclusive zone | source reserves actual surface height, updates on resize; KWin validation required |
| Dock anchoring and pointer region | event-driven rounded input masks implemented; KWin input validation required |
| Popup placement and keyboard | independent native host implemented; hidden preview is no longer the popup parent; KWin validation required |
| Maximization and focus restoration | covered by the new isolated cloud test; current-commit results still required |
| Mock/Visual Lab regression path | preserved in CircleCI configuration |

## Isolated cloud acceptance

`tools/native-session-smoke.sh` runs a nested X11-backend KWin over Xvfb/Mesa,
inside a private `dbus-run-session`, runtime directory and configuration. It
never connects to the owner's niri session. Dedicated Ubuntu/Fedora jobs build
`OWODE_BUILD_NATIVE_TESTS=ON`; the tools refuse a normal host environment.

The test loads the production QML surfaces, starts a separate ordinary Qt
Wayland application, queries actual KWin window geometry/types through a
temporary script, and injects pointer/keyboard input through KWin's test
protocol. It checks maximization, transparent gaps, launcher search input,
Escape/outside dismissal, focus restoration, modifier-drag and ordinary close.
Screenshots show the actual nested compositor output, not an assembled mockup.
It also launches the actual `klde-shell --native-shell-surfaces` CLI. Raw
Wayland requests, configure acknowledgements, KWin snapshots/version/support
information, interaction results and shutdown evidence accompany the captures.

The copied test-only protocol is documented in [third-party notices](../legal/third-party.md).
It is never linked into the production shell and must not be used as an input
backend. No Plasma Shell, host settings, privileged helper or display-manager
entry is installed. Ubuntu also builds the C++ LayerShellQt interface now;
its QML module is not a prerequisite for our C++ adapter.

KWin interprets the layer-shell namespace as a window-type hint. The adapter
uses canonical `desktop`, `dock` and `on-screen-display` namespaces while
retaining owoDE object names for role diagnostics. A branded namespace would
fall back to KWin's Normal type, despite requesting the background layer; see
[KWin's implementation](https://github.com/KDE/kwin/blob/Plasma/6.7/src/layershellv1window.cpp).
Protocol verification therefore checks namespace, layer and anchors together.

Distribution KWin binaries may carry `cap_sys_nice`, which restricted cloud
containers do not grant. The runner copies only the binary bytes into its own
temporary runtime, verifies an identical hash and absence of file capabilities,
and leaves the distribution binary unchanged. It does not add container
capabilities or claim representative scheduling/GPU performance.

This is single-output cloud correctness evidence. Owner-host interaction,
multi-output/hotplug, session services, locking and daily-use acceptance remain
separate gates. Native panels use the opaque material fallback because they do
not capture unrelated application content. Native compositor blur is later work.
The independent calculator engine port does not change this milestone's native
surface scope. No compositor rewrite or advanced tiling is included.

The isolated runner installs a private desktop entry for the test executable with
`X-KDE-Wayland-Interfaces=org_kde_kwin_fake_input` and refreshes only its private
service cache. KWin's normal permission checks remain enabled. The production
shell does not request input injection. This follows KWin's
[service authorization](https://invent.kde.org/plasma/kwin/-/blob/Plasma/6.7/src/utils/serviceutils.h)
and [Wayland interface filtering](https://invent.kde.org/plasma/kwin/-/blob/Plasma/6.7/src/wayland_server.cpp).
