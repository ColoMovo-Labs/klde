# System application discovery and launching

`DesktopApplicationBackend` is the first real application integration. It uses
distribution KF6 Service/KConfig and KIOGui APIs, with no Plasma Shell process.
The ordinary window, Visual Lab and Qt Design Studio still use mock applications.
This change does not implement KWin running-window or active-window tracking.

## Discovery and presentation

An asynchronous scan reads `applications/` below Qt's XDG generic data roots in
priority order. Nested paths produce desktop-file IDs by replacing `/` with `-`.
The first ID wins, including a user override marked Hidden. KDesktopFile/KService
parse metadata, localization, TryExec, NoDisplay and desktop/platform visibility.
No executable command is parsed by our own code. A file/directory watcher coalesces
changes; reopening the launcher also requests a refresh. There is no idle poll.

The model receives plain application entries. Runtime icons resolve through a
Qt image provider using the installed icon theme or the desktop file's absolute
icon path. Designer/mock icons continue using the original shared SVG assets.
The shared `Glyph` handles both without importing a C++ module into the designer.

The launcher displays/searches the complete discovered catalog. The Dock uses
a separate filtered model: pinned applications plus compositor-confirmed running
applications. Initially the real Dock can contain only its launcher button.
Right-click an application in the launcher, or use its Menu key / Shift+F10,
to pin or unpin it. IDs are persisted in QSettings. Extra pins remain within
the rounded Dock surface through horizontal scrolling.

## Launch boundary

Launch accepts only an ID in the discovered catalog and revalidates that file.
An asynchronous `KIO::ApplicationLauncherJob` handles desktop Exec field codes,
quoting, working directory and the platform's launch mechanisms. Errors return
to the shell as a notice. Neither acceptance nor a successful launch job marks
an application running or active: those states require actual KWin observations.
No arbitrary command string or desktop file path is accepted from QML.

Ordinary preview defaults to `--applications mock`. Native mode defaults to
`--applications system` and fails explicitly if its KF6 dependencies are absent.
An isolated native visual test can request `--applications mock`.
The cloud preset requires the real implementation on Ubuntu and Fedora, preventing
optional compilation from silently skipping the implementation in static analysis.

```sh
# Use the existing cloud-built binary; this is not a local build command.
OWODE_MODE=native OWODE_APPLICATIONS=system OWODE_SHELL=/path/to/klde-shell \
  bash tools/run-owode-session.sh
```

The nested runner preserves read access to the owner's installed application
data root but keeps its config, cache, data writes and D-Bus session private.
Pin preferences in that temporary configuration last only for that nested run.
No host default session or compositor settings are changed. X11/Xwayland clients
are still a separate integration gap; this runner only provides an inner Wayland
display. D-Bus activation, terminal selection and focus behavior must be verified
with real distribution applications before claiming broad daily-use compatibility.

## Verification

`desktop-applications` runs in a private D-Bus session and temporary XDG roots.
It checks override precedence, visibility rules, stable nested IDs, localization,
actual icon loading, installation/edit/removal notifications, pin persistence,
model filtering and QML factory selection. It starts a controlled executable and
checks its arguments and working directory, and separately checks launch failure.
Mock state must not overwrite the real catalog or invent running indicators.

These contracts do not replace the nested KWin acceptance test. Real launcher
input, activation/focus and window-to-desktop-ID matching remain the next native
gate. Existing KWin surface tests, design scenes, screenshots and packaging jobs
continue alongside these tests. Compilation and tests run in CircleCI/CNB.

References: [Desktop Entry specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/),
[KDesktopFile](https://api.kde.org/kdesktopfile.html),
[KService](https://api.kde.org/kservice.html),
[ApplicationLauncherJob](https://api.kde.org/kio-applicationlauncherjob.html).
