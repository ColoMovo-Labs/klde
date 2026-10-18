#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

printf 'LoMoDE Real Session probe\n'
printf '  host: %s\n' "$(uname -sr)"
printf '  session type: %s\n' "${XDG_SESSION_TYPE:-unset}"
printf '  wayland display: %s\n' "${WAYLAND_DISPLAY:-unset}"
printf '  dbus session: %s\n' "${DBUS_SESSION_BUS_ADDRESS:+present}${DBUS_SESSION_BUS_ADDRESS:-unset}"

if command -v rpm >/dev/null 2>&1; then
    for package in kwin layer-shell-qt layer-shell-qt-devel qt6-qtwayland-devel wayland-devel wayland-protocols-devel; do
        if rpm -q "$package" >/dev/null 2>&1; then
            printf '  package %-24s %s\n' "$package" "$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' "$package")"
        else
            printf '  package %-24s missing\n' "$package"
        fi
    done
fi

if command -v kwin_wayland >/dev/null 2>&1; then
    printf '  kwin_wayland: %s\n' "$(kwin_wayland --version 2>&1 | head -1)"
    printf '  kwin help flags:\n'
    kwin_wayland --help 2>&1 | rg -- '--socket|--virtual|--xwayland|--no-global-shortcuts|--exit-with-session' || true
else
    printf '  kwin_wayland: missing\n'
fi

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin org.kde.KWin.supportInformation >/dev/null 2>&1 \
        && printf '  org.kde.KWin D-Bus service: registered\n' \
        || printf '  org.kde.KWin D-Bus service: not available\n'
else
    printf '  qdbus6: missing (QtDBus probe is used by the shell)\n'
fi

layer_shell_paths=(
    /usr/lib64/qt6/qml/org/kde/layershell/qmldir
    /usr/lib/qt6/qml/org/kde/layershell/qmldir
)
layer_shell=missing
for path in "${layer_shell_paths[@]}"; do
    if [[ -f "$path" ]]; then
        layer_shell=present
        break
    fi
done
printf '  LayerShellQt QML module: %s\n' "$layer_shell"

if [[ "${XDG_SESSION_TYPE:-}" != "wayland" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    printf 'RESULT: safe preview-only host; no Wayland compositor is running here.\n'
elif ! command -v kwin_wayland >/dev/null 2>&1; then
    printf 'RESULT: Wayland may be available, but kwin_wayland is required before isolated testing.\n'
else
    printf 'RESULT: prerequisites need version-specific KWin and LayerShellQt validation.\n'
fi
