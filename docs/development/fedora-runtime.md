# Fedora 44 runtime bring-up

Fedora is the first runtime target for LoMoDE Real Session 0.1. The build
environment and the compositor runtime are intentionally separate. A successful
container build proves dependency resolution and compilation; it does not prove
that KWin manages LoMoDE windows.

## Package mapping

| Requirement | Fedora package / provider | Validation |
| --- | --- | --- |
| KWin Wayland compositor | `kwin` (provides `kwin-wayland` and installs `kwin_wayland`) | `rpm -q kwin`; `command -v kwin_wayland` |
| Layer shell runtime | `layer-shell-qt` | `rpm -q layer-shell-qt` |
| Layer shell development files | `layer-shell-qt-devel` | `rpm -q layer-shell-qt-devel` |
| Qt Wayland client | `qt6-qtwayland-devel` | `rpm -q qt6-qtwayland-devel` |
| Wayland headers/protocols | `wayland-devel`, `wayland-protocols-devel` | `rpm -q wayland-devel wayland-protocols-devel` |
| Toolchain | `@development-tools`, `cmake`, `ninja-build`, `ccache` | `g++ --version`, `cmake --version` |

Fedora 44 currently publishes KWin 6.6/6.7 builds and LayerShellQt 6.7.x.
The exact installed version must be captured before testing because KWin
command-line flags, scripting APIs and downstream packaging can change.

Authoritative package references:

- [Fedora KWin package](https://packages.fedoraproject.org/pkgs/kwin/kwin/fedora-44.html)
- [Fedora LayerShellQt package](https://packages.fedoraproject.org/pkgs/layer-shell-qt/layer-shell-qt/index.html)
- [Fedora LayerShellQt source/subpackages](https://packages.fedoraproject.org/pkgs/layer-shell-qt/)

## Reproducible build container

From the repository root:

```sh
bash tools/setup-fedora-container.sh
podman run --rm -it --userns=keep-id \
  -v "$PWD:/workspace:Z" -w /workspace \
  localhost/lomode-fedora:44
```

The container does not mount the host Wayland socket, `/dev/dri`, the host
session bus or arbitrary home directories. Toolbx may be used for convenience,
but it shares host interfaces and is not treated as a security boundary.

## Runtime validation

Inside the Fedora host or a deliberately configured test environment:

```sh
bash tools/probe-real-session.sh
LOMODE_SHELL=/path/to/cloud-built/klde-shell \
LOMODE_APP='a-real-wayland-application' \
bash tools/run-lomode-session.sh
```

The launcher creates a private session D-Bus, checks `kwin_wayland --help`,
requests a unique Wayland socket and owns cleanup of only its child processes.
It does not change the display manager or stop host compositor processes.

## Verification levels

1. **Build:** the Fedora container configures and compiles LoMoDE.
2. **Wayland client:** the Qt shell connects to a Wayland display.
3. **Real compositor:** the exact nested KWin process owns the socket and
   creates the shell surfaces.
4. **Session:** a genuine application is managed by that KWin process, focus
   changes are observed and the isolated session exits cleanly.

Only levels 1 and the existing cloud preview contracts are currently verified
in CI. Levels 3–4 require a Fedora runtime with KWin and LayerShellQt installed.
