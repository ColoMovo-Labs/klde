# Platforms and source portability

KLDE is an upstream desktop project. A future Ubuntu LTS-based KLDE distribution
may consume it, but must not become a dependency of the shell. The C++/QML code
uses Qt and capability interfaces rather than Ubuntu-specific commands.

| Environment | Current validation | Package status |
| --- | --- | --- |
| Ubuntu 26.04 / Ubuntu Kylin lineage | Primary CircleCI build, analysis, CTest, QML and three rendering paths | Experimental `.deb`, install/runtime/removal checked in a fresh Ubuntu container |
| Fedora 44 | Independent CircleCI CMake/Ninja build, full CTest, offscreen/software startup and cloud-built packages | Experimental `.rpm` and `.tar.gz` bundles; no login-session package |
| Arch and other distributions | Public Qt 6.8+ / CMake source interface; not currently tested by CI | Community/source builds; no official package claim |

These rows describe the configured acceptance checks. A platform is verified for
a particular revision only when that revision's CircleCI jobs pass. They do not
promise daily-driver readiness, all compositor integrations or a GPU/hardware
compatibility matrix.

## Ubuntu source dependencies

The exact development and correctness-test environment is recorded in
[.circleci/packages.txt](../../.circleci/packages.txt). Distribution QML runtime
modules and `qt6-svg-plugins` matter in addition to the development libraries.
The `.deb` package declares those runtime dependencies and resolves ELF libraries
through `dpkg-shlibdeps`. See [packaging](../../packaging/README.md).

## Fedora source dependencies

CircleCI uses the pinned release family `fedora:44` with distribution updates,
not Rawhide or an unversioned latest image. The
[manifest](../../.circleci/fedora-packages.txt) names `gcc-c++`, `cmake`,
`ninja-build`, `qt6-qtbase-devel`, `qt6-qtdeclarative-devel`,
`qt6-qtwayland-devel`, `qt6-qtsvg`, `layer-shell-qt-devel`, Wayland protocol
headers, `dejavu-sans-fonts` and supporting checkout/cache/metadata tools.

Fedora's [qt6-qtdeclarative package](https://packages.fedoraproject.org/pkgs/qt6-qtdeclarative/qt6-qtdeclarative/fedora-44-updates.html)
contains QtQuick Controls/Basic, Effects, Layouts, Templates and QtTest imports.
The [qt6-qtbase-gui package](https://packages.fedoraproject.org/pkgs/qt6-qtbase/qt6-qtbase-gui/fedora-44.html)
supplies the offscreen/XCB platform plugins; [qt6-qtsvg](https://packages.fedoraproject.org/pkgs/qt6-qtsvg/qt6-qtsvg/fedora-44.html)
supplies SVG support. Use the actual `qt6-qtdeclarative-devel` package rather
than assuming a separate Quick Controls development package is necessary.

The Fedora job builds from its own checkout and never consumes Ubuntu objects
or plugins. It publishes the installed RPM inventory and Qt paths/version data.
Compiler/dependency caches are separate from Ubuntu caches. Only software
rendering is exercised in this Fedora job; Ubuntu's llvmpipe checks do not prove
Fedora hardware acceleration or a compositor session works. The same job stores
experimental `klde-shell-preview-*.rpm` and `owode-shell-fedora44-*.tar.gz`
user bundles as CircleCI artifacts. Neither registers a login session.

## Fedora cloud bundle installation

Open the successful CircleCI `core` workflow for the revision you want, open the
`fedora-build` job, and download the files under `artifacts/fedora-package/`.
On Fedora 44, the RPM is the normal installation path:

```sh
sudo dnf install ./klde-shell-preview-*.rpm
```

For a rootless install, use the matching tarball instead:

```sh
mkdir -p "$HOME/.local"
tar -xzf owode-shell-fedora44-*.tar.gz -C "$HOME/.local" --strip-components=1
hash -r
"$HOME/.local/bin/klde-shell"
```

This launches the standalone preview window. To exercise the isolated nested
KWin path, clone the matching source revision for the launcher script and run:

```sh
OWODE_SHELL="$HOME/.local/bin/klde-shell" \
OWODE_MODE=native \
OWODE_APP='your-wayland-application' \
bash tools/run-lomode-session.sh
```

The native path still requires a Fedora KWin runtime and is not a replacement
for the host login session.

## Build interface

The same source interface applies on both platforms:

```sh
cmake --preset ci
cmake --build --preset ci --parallel 2
ctest --test-dir build/ci --output-on-failure
```

These commands are run in CircleCI for acceptance. Local editing/review and
lightweight experiments remain optional; a local build cannot substitute for
current-head cloud checks. Runtime resource efficiency and cloud build throughput
are separate requirements.

Qt 6.8 is the public API minimum. The distribution jobs normally use newer Qt;
they do not yet prove a minimum-version Qt 6.8 build. There are no host-service
package requirements for mocked capabilities. When real backends arrive, probe
optional services at runtime and document feature-specific dependencies rather
than making every distribution install all Ubuntu Kylin services.
