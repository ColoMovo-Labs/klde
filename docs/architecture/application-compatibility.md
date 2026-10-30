# GNOME and KDE application compatibility

owoDE keeps `XDG_CURRENT_DESKTOP=owoDE` for its session. Most GTK/libadwaita and
KDE/Qt applications can run on another desktop when their libraries, display
server and required services exist. A desktop-name string cannot supply missing
GNOME Shell extensions, KDED modules, settings daemons, a session locker,
polkit agent or portal backend.

The application catalog includes otherwise valid GNOME/KDE `OnlyShowIn` menu
entries when running in owoDE. It still respects `Hidden`, `NoDisplay`, `TryExec`,
platform restrictions and an explicit `NotShowIn=owoDE`. This is a deliberate
cross-desktop menu policy; it does not rewrite distribution desktop files or
silently impersonate both desktops for every process.

For a newly started application that specifically checks the desktop identity:

```sh
owode-run --gnome -- gnome-calculator
owode-run --kde -- kcalc
owode-run --native -- an-application
```

Only that child receives the selected desktop identity. KDE mode additionally
sets the conventional KDE session hints. The real session name, display sockets
and D-Bus address remain unchanged; commands/arguments are passed directly with
`exec`, with no shell parsing. The helper does not force a nonexistent Qt theme
plugin or overwrite the user's GTK settings. It cannot change the environment
of an already running D-Bus-activated application; close it before testing a
different profile. Normal catalog launches continue to use KIO's desktop-entry
handling, including normal D-Bus activation, rather than a hand-written Exec parser.

The initial Fedora integration cases are GNOME Calculator (GTK4/libadwaita) and
KCalc (KDE/Qt). The cloud test must record actual KWin-managed windows, processes
and a screenshot. Window startup is an initial compatibility check, not a claim
that all GNOME/KDE applications or all of their features work.

Portal selection must use an owoDE-specific configuration and tested backend
implementations, rather than globally pretending the session is GNOME/KDE.
Portal/file dialog/screen sharing acceptance remains in the production gates.

References: [desktop entry visibility](https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html),
[portal configuration](https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html),
[Fedora GNOME Calculator](https://packages.fedoraproject.org/pkgs/gnome-calculator/gnome-calculator/fedora-44.html),
[Fedora KCalc](https://packages.fedoraproject.org/pkgs/kcalc/kcalc/fedora-44.html).
