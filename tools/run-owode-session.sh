#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# A visible, isolated nested runtime, never a replacement for the login session.
set -euo pipefail
root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_bin=${OWODE_SHELL:-$(command -v klde-shell || true)}
shell_bin=${shell_bin:-$root_dir/build/ci/bin/klde-shell}
kwin_bin=$(command -v "${KWIN_WAYLAND_BIN:-kwin_wayland}" || true)
mode=${OWODE_MODE:-preview}
backend=${OWODE_BACKEND:-auto}
case "$mode" in preview|native) ;; *) echo 'OWODE_MODE must be preview or native.' >&2; exit 2;; esac
[[ -x "$shell_bin" && -n "$kwin_bin" ]] || {
    echo 'Set OWODE_SHELL to the cloud-built binary and install KWin Wayland.' >&2; exit 3;
}
command -v setsid >/dev/null || { echo 'setsid is required.' >&2; exit 4; }
command -v dbus-run-session >/dev/null || { echo 'dbus-run-session is required.' >&2; exit 4; }
shell_bin=$(realpath "$shell_bin")
if [[ "$backend" == auto ]]; then
    if [[ -n "${DISPLAY:-}" ]]; then backend=x11
    elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then backend=wayland
    else echo 'No parent display; select OWODE_BACKEND=virtual explicitly for headless use.' >&2; exit 5; fi
fi
case "$backend" in x11|wayland|virtual) ;; *) echo 'Unknown OWODE_BACKEND.' >&2; exit 5;; esac
export OWODE_PARENT_DISPLAY=${DISPLAY:-}
export OWODE_PARENT_WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}
if [[ -n "$OWODE_PARENT_WAYLAND_DISPLAY" && "$OWODE_PARENT_WAYLAND_DISPLAY" != /* ]]; then
    export OWODE_PARENT_WAYLAND_DISPLAY="${XDG_RUNTIME_DIR:?}/$OWODE_PARENT_WAYLAND_DISPLAY"
fi
runtime_dir=$(mktemp -d /tmp/owode-session-runtime-XXXXXX)
evidence_dir=${OWODE_EVIDENCE_DIR:-$(mktemp -d /tmp/owode-session-evidence-XXXXXX)}
mkdir -p "$evidence_dir" "$runtime_dir/config" "$runtime_dir/cache" "$runtime_dir/data"
evidence_dir=$(realpath "$evidence_dir")
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
# Copy bytes without distribution file capabilities; never modify system KWin.
python3 - "$kwin_bin" "$runtime_dir/kwin_wayland" <<'PY'
import os
from pathlib import Path
import shutil
import sys
source, target = map(Path, sys.argv[1:])
shutil.copyfile(source, target)
target.chmod(0o700)
if 'security.capability' in os.listxattr(target):
    raise SystemExit('Private KWin copy unexpectedly carries capabilities')
PY
# Preserve read access to the installed user application catalog while keeping writes private.
export XDG_DATA_DIRS="${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config"
export XDG_CACHE_HOME="$runtime_dir/cache" XDG_DATA_HOME="$runtime_dir/data"
env -u WAYLAND_DISPLAY dbus-run-session -- bash -s -- \
    "$runtime_dir/kwin_wayland" "$shell_bin" "$mode" "$backend" "$evidence_dir" <<'INNER'
set -euo pipefail
kwin_bin=$1; shell_bin=$2; mode=$3; backend=$4; evidence_dir=$5
socket_name=owode-nested
kwin_pid=; shell_pid=; app_pid=
cleanup() {
    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill -TERM -- "-$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
    for pid in "$shell_pid" "$kwin_pid"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
help_text=$("$kwin_bin" --help 2>&1)
grep -q -- '--socket' <<< "$help_text" || { echo 'KWin must support --socket.' >&2; exit 6; }
args=(--socket "$socket_name" --no-global-shortcuts)
case "$backend" in
    x11)
        [[ -n "$OWODE_PARENT_DISPLAY" ]] || { echo 'No parent X11 display.' >&2; exit 7; }
        args+=(--x11-display "$OWODE_PARENT_DISPLAY") ;;
    wayland)
        [[ -n "$OWODE_PARENT_WAYLAND_DISPLAY" ]] || { echo 'No parent Wayland display.' >&2; exit 7; }
        args+=(--wayland-display "$OWODE_PARENT_WAYLAND_DISPLAY") ;;
    virtual) args+=(--virtual) ;;
esac
"$kwin_bin" --version > "$evidence_dir/kwin-version.txt" 2>&1
printf 'backend=%s\nmode=%s\nsocket=%s\nshell=%s\n' "$backend" "$mode" "$socket_name" "$shell_bin" > "$evidence_dir/session.txt"
echo "Nested owoDE logs: $evidence_dir"
"$kwin_bin" "${args[@]}" > "$evidence_dir/kwin.log" 2>&1 &
kwin_pid=$!
for _ in $(seq 1 150); do
    [[ -S "$XDG_RUNTIME_DIR/$socket_name" ]] && break
    kill -0 "$kwin_pid" 2>/dev/null || { tail -60 "$evidence_dir/kwin.log" >&2; exit 8; }
    sleep 0.1
done
[[ -S "$XDG_RUNTIME_DIR/$socket_name" ]] || { echo 'Nested socket startup timed out.' >&2; exit 9; }
# X11 clients are deliberately unsupported here until inner Xwayland startup and
# its DISPLAY handoff are implemented. They must never escape into host Xwayland.
unset DISPLAY
export WAYLAND_DISPLAY="$socket_name" QT_QPA_PLATFORM=wayland GDK_BACKEND=wayland SDL_VIDEODRIVER=wayland
export XDG_CURRENT_DESKTOP=owoDE XDG_SESSION_DESKTOP=owode XDG_SESSION_TYPE=wayland
export XCURSOR_THEME=${XCURSOR_THEME:-Bibata-Modern-Classic} XCURSOR_SIZE=${XCURSOR_SIZE:-24}
shell_args=(--view desktop)
[[ "$mode" == native ]] && shell_args=(--native-shell-surfaces --applications "${OWODE_APPLICATIONS:-system}")
"$shell_bin" "${shell_args[@]}" > "$evidence_dir/shell.log" 2>&1 &
shell_pid=$!
if [[ -n "${OWODE_APP:-}" ]]; then
    setsid sh -c "$OWODE_APP" > "$evidence_dir/application.log" 2>&1 &
    app_pid=$!
fi
wait -n "$shell_pid" "$kwin_pid"
INNER
