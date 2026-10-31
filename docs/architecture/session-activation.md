# Managed-session activation environment

The installed session client imports a small allowlist into its session D-Bus
activation environment after KWin has supplied its own Wayland/Xwayland display.
If that bus already has a systemd user manager, the same import updates it through
`dbus-update-activation-environment --systemd`. Private container sessions without
a user manager update their own D-Bus daemon only. The shell starts only after
that import succeeds.

The allowlist is `DISPLAY`, `WAYLAND_DISPLAY`, `XAUTHORITY`,
`XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP` and `XDG_SESSION_TYPE`. Missing X11
fields are imported as empty strings to replace stale values; D-Bus cannot unset
variables. The current desktop is owoDE, with `owode` as the session-entry ID.
No credentials, arbitrary environment, Qt theme plugin, GNOME/KDE compatibility
profile or test flags are imported. `owode-run` still changes only its executed
child. Ordinary previews and the safe nested developer runner do not run this
managed-session bootstrap or update the owner's existing activation environment.

The installed-session cloud test creates a private D-Bus service before starting
its private bus. Its Exec line contains no display or QPA override. The daemon
starts a genuine Qt application after the installed session client imports its
environment. Assertions compare its bus-owned PID, actual Wayland platform,
inner Xwayland display and desktop/session identity against KWin's session
client. The original direct Wayland/Xwayland and GNOME/KDE app checks remain.

This is startup-environment integration, not a complete portal implementation.
Portal backend selection, consent, screencasting, activation tokens, environment
cleanup/ownership across concurrent graphical sessions, IME and autostart still
need separate acceptance. Do not call this import a proof that every GNOME/KDE
application or sandboxed workload works.

Reference: [D-Bus activation environment utility and limitations](https://dbus.freedesktop.org/doc/dbus-update-activation-environment.1.html).
