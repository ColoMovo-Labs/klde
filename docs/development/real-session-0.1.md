# owoDE Real Session 0.1

This checkpoint ends the mock-first visual milestone and starts the safe
KWin/Wayland session path. It deliberately does not replace the host session.

## Repository reality check

The shell is a native Qt 6/QML/C++20 application. The existing Visual Lab and
mock providers remain intact. `WindowManagerBackend` is currently backed by
`MockWindowManagerBackend`; no real KWin window-management claims are made yet.

The first runtime boundary is `Shell.session`, backed by
`SessionRuntimeBackend`. It reports Wayland, the `org.kde.KWin` session-bus
service and LayerShellQt availability without starting processes or polling.

## Current host findings

The development host used for the original checkpoint has Qt 6.11 and DBus,
but no `kwin_wayland` executable and no installed LayerShellQt QML module. The
owner has since supplied photographic evidence of the first visible nested
KWin run from Fedora 44 + niri; that evidence is preserved in
[First Light](first-light.md). It demonstrates preview/client coexistence, but
does not establish native layer-shell roles. The local host remains blocked for
protocol verification until KWin and LayerShellQt are installed.

Run the read-only probe with:

```sh
bash tools/probe-real-session.sh
```

## Isolated run path

Once a compatible KWin Wayland package and a cloud-built shell binary exist,
run the isolated harness:

```sh
OWODE_SHELL=/path/to/klde-shell \
OWODE_APP='your-real-wayland-application' \
bash tools/run-owode-session.sh
```

The harness creates a private session D-Bus, requests a named Wayland socket,
starts KWin only if the binary exists, waits for that socket, launches the
native shell and optionally launches the supplied genuine application. Cleanup
terminates only the nested processes. It never edits the host session or
display-manager configuration.

The runner gates optional KWin flags from `kwin_wayland --help` instead of
assuming a KWin 5 command line. If a prerequisite or socket is missing it
exits with a clear error.

## Checkpoint status

| Checkpoint | Status |
| --- | --- |
| Repository and native-renderer inspection | verified |
| Read-only Wayland/KWin capability probe | implemented |
| Safe isolated KWin launcher | implemented; First Light photograph supplied from Fedora 44 + niri |
| Nested KWin preview alongside a genuine Qt client | owner-supplied photographic evidence; process log pending |
| Proper LayerShellQt wallpaper/ribbon/dock surfaces | pending target-KWin probe |
| Genuine application managed by nested KWin | pending target-KWin probe |
| Real workspace/focus adapter | pending public/versioned KWin API probe |

CircleCI continues to validate the mock shell and unit/QML contracts. It must
not mark KWin runtime integration as passed when the runner is unavailable.
