# owoDE session runtime boundary

The production shell remains a Qt 6/QML application, but it now exposes a
read-only `Shell.session` capability probe. `SessionRuntimeBackend` observes the
current process environment and the session D-Bus service registry; it never
starts KWin, changes the display manager, or treats a preview window as a
desktop surface.

The probe reports four separate facts:

- Wayland session detection from `XDG_SESSION_TYPE` or `WAYLAND_DISPLAY`.
- Registration of `org.kde.KWin` on the session bus.
- Presence of a LayerShellQt QML module in standard Qt 6 locations.
- A human-readable diagnostic explaining which prerequisite is missing.

`realSessionReady` is true only when Wayland, KWin and LayerShellQt are all
observed. The result is intentionally conservative. The next adapter must
still validate the exact KWin version, supported layer roles, output selection,
exclusive zones and popup behavior before enabling live shell surfaces.

The mock window backend remains the default for Visual Lab and CircleCI. A real
KWin window/workspace adapter must be selected explicitly after a versioned
KWin protocol/API probe; no QML component is allowed to infer compositor state
from a mock workspace indicator.
