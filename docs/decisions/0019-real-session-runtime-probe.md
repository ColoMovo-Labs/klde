# 0019 — Gate real KWin session work behind runtime capability probes

## Context

owoDE is moving from a mock-first visual shell to a real KWin-based Wayland
session. The current development host does not contain `kwin_wayland` or
LayerShellQt, and KWin versions expose different command-line and scripting
surfaces.

## Decision

Add a read-only `SessionRuntimeBackend` and an isolated `dbus-run-session`
launcher before enabling live shell surfaces. Require Wayland, the KWin D-Bus
service and LayerShellQt to be observed before reporting `realSessionReady`.
Keep `MockWindowManagerBackend` as the permanent visual-test backend until an
exact KWin adapter profile has been verified.

## Consequences

- The host desktop is never replaced as an exploratory test step.
- Missing KWin packages fail clearly instead of producing a fake integration.
- CircleCI can continue to compile and test the mock shell without a display
  compositor.
- Real wallpaper, ribbon and dock layer roles remain blocked until the target
  KWin/LayerShellQt combination is installed and probed.

## Alternatives considered

- Replacing the host session immediately: rejected as unsafe and unnecessary.
- Treating a normal Qt top-level window as a panel: rejected because it does not
  establish layer-shell roles, exclusive zones or correct stacking.
- Assuming one outdated KWin command line: rejected because KWin 5/6 and
  downstream forks differ.
