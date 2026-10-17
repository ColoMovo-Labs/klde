#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
trap 'printf "Package runtime check failed at line %s\n" "$LINENO" >&2' ERR

# This helper runs only in a fresh CircleCI Ubuntu runtime job, after apt has
# resolved the package dependencies. Do not run it on a developer's desktop.
test "${CIRCLECI:-}" = true
mkdir -p artifacts/package-runtime
runtime_dir="$(mktemp -d)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
export XDG_RUNTIME_DIR="$runtime_dir"
unset QML_IMPORT_PATH QML2_IMPORT_PATH QT_PLUGIN_PATH

test "$(command -v klde-shell)" = /usr/bin/klde-shell
dpkg-query -W -f='${Status}\n' klde-shell-preview | grep -Fx 'install ok installed'
dpkg-query -W > artifacts/package-runtime/packages.txt
dpkg -L klde-shell-preview > artifacts/package-runtime/installed-files.txt
desktop-file-validate /usr/share/applications/org.klde.shell.preview.desktop
test -s /usr/share/doc/klde-shell-preview/copyright
test -s /usr/share/doc/klde-shell-preview/LICENSE
test -s /usr/share/doc/klde-shell-preview/CC-BY-SA-4.0.txt
test -s /usr/share/doc/klde-shell-preview/OFL-1.1.txt
test -s /usr/share/doc/klde-shell-preview/Comfortaa-OFL.txt
# Developer packages would mask a missing QML/plugin dependency in the .deb.
if dpkg-query -W -f='${binary:Package} ${db:Status-Status}\n' 'qt6-*-dev' 2>/dev/null | grep -q ' installed$'; then
    echo 'Unexpected Qt development package in the runtime-only job' >&2
    exit 1
fi

env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    /usr/bin/klde-shell --smoke-test --view quick-settings \
    --capture "$PWD/artifacts/package-runtime/offscreen.png" \
    > artifacts/package-runtime/offscreen.log 2>&1
xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 glxinfo -B > artifacts/package-runtime/glxinfo.txt
xvfb-run -a env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
    LIBGL_ALWAYS_SOFTWARE=1 QSG_INFO=1 \
    /usr/bin/klde-shell --smoke-test --view blur --audit-idle \
    --capture "$PWD/artifacts/package-runtime/blur.png" \
    > artifacts/package-runtime/blur.log 2>&1
test -s artifacts/package-runtime/offscreen.png
test -s artifacts/package-runtime/blur.png

env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    /usr/bin/klde-shell --smoke-test --locale zh_CN --voice cute --view language \
    --capture "$PWD/artifacts/package-runtime/language-zh_CN.png" \
    > artifacts/package-runtime/language-zh_CN.log 2>&1
test -s artifacts/package-runtime/language-zh_CN.png
test -s /usr/share/fcitx5/themes/klde-expressive-light/theme.conf
test -s /usr/share/fcitx5/themes/klde-expressive-dark/theme.conf

apt-get purge -y klde-shell-preview
if command -v klde-shell; then
    echo 'Shell executable survived package removal' >&2
    exit 1
fi
test ! -e /usr/share/applications/org.klde.shell.preview.desktop
test ! -e /usr/share/icons/hicolor/scalable/apps/klde.svg
