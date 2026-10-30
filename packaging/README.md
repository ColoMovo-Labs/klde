# Experimental packaging

CircleCI builds a real `klde-shell-preview` Debian binary package for Ubuntu 26.04
with CPack. It contains the standalone preview executable, desktop entry, original
icon and license/copyright documents. It does not install a login session,
privileged helper, service or replacement for the host desktop.

The `packaging-check` job generates ELF library dependencies with
`dpkg-shlibdeps` and adds the QML modules, platform plugins and SVG decoder loaded
at runtime. The `deb-runtime` job starts from a separate Ubuntu image, installs
the package with `apt` and `--no-install-recommends`, captures its offscreen and
OpenGL/llvmpipe paths, then purges it and checks executable/desktop/icon removal.
Qt development packages are rejected in that runtime job. This catches dependency
omissions that an install inside the development container could hide.

The package uses distribution Qt libraries rather than bundling Qt. KLDE's own
QML modules and assets are embedded. On Ubuntu 26.04, SVG decoding requires
`qt6-svg-plugins`; `libqt6svg6` alone does not install the image-format plugin.
See the [distribution package file list](https://packages.ubuntu.com/resolute/all/qt6-svg-plugins/filelist).
`QtQuick.Effects`, Basic controls, templates and layouts also need their runtime
QML packages even when ELF dependency generation succeeds.

## Artifacts and source

The package artifact directory also contains the matching committed source
archive, full source commit, checksums and control/content listings. Snapshot
versions use the project version followed by a `0.git<commit-time>.<commit>`
Debian revision. The source archive includes KLDE source, assets, license texts
and build scripts; third-party runtime libraries come from Ubuntu repositories
and their corresponding source packages. Keep the binary and corresponding
source available together when redistributing GPL-covered artifacts. A passing
CI job is not a complete distribution/release compliance audit.

Run only in the authoritative cloud build:

```sh
bash tools/package-deb.sh build/ci
```

The CI package maintainer field identifies `KLDE contributors`, with project
contact via [GitHub](https://github.com/ColoMovo-Labs/klde/issues). No email address
is invented. Debian/Ubuntu archive submission requires a designated maintainer
and policy-compliant contact metadata. This experimental CPack artifact is not
represented as archive-ready, a signed release or an official stable package.
Upgrade/downgrade tests, full lintian review, reproducibility and release signing
remain packaging work.

Fedora 44 has an independent source build, CTest, offscreen startup job and
cloud-built packages under the CircleCI `fedora-build` job's
`artifacts/fedora-package/` directory. The preferred artifact is
`klde-shell-preview-*.rpm`, installable with `dnf`; the matching
`owode-shell-fedora44-*.tar.gz` is a rootless `~/.local` fallback. The separate `owode-session-*.noarch.rpm` registers an opt-in Wayland
login entry and depends on its exact matching shell version. The preview RPM
and rootless tarball still do not change the login manager. See
[the session guide](../docs/development/fedora-login-session.md). Installation and tested scope are documented in
[platforms.md](../docs/development/platforms.md).
