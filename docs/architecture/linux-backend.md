# owoDE Linux backend boundary

The native shell keeps Linux integration behind small C++ boundaries. A runtime
probe may report the current Wayland display, session bus, KWin hints and
LayerShellQt availability, but discovery is not the same as claiming a shell
surface. `SessionRuntimeBackend` remains read-only and does not start services,
modify the host compositor or request privileges.

LayerShellQt is an optional build/runtime dependency. The public
`LayerShellQt::Interface` API is used only by `NativeSurfaceController`; no
private Qt Wayland headers are required. The ordinary QML preview remains the
fallback when the interface package or a Wayland QPA is unavailable.

Future adapters should be added one service at a time:

- NetworkManager, UPower, PipeWire / WirePlumber and power-profiles-daemon via
  documented D-Bus APIs;
- active window and workspace state through a versioned KWin adapter;
- XDG desktop-file discovery and launching through standard application
  metadata;
- session actions through logind and polkit.

Each adapter must expose availability and capability state, use asynchronous
subscriptions instead of polling, keep native handles in C++, and leave
MockBackend available for Visual Lab and CircleCI. A real target-host log must
support every claim about KWin behavior; static configuration or a screenshot
does not establish protocol roles.
