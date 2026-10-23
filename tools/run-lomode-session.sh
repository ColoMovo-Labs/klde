#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Start a nested KWin session without changing the host display manager/session.
# The filename is retained for compatibility; the public runtime is owoDE.
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_bin=${OWODE_SHELL:-${LOMODE_SHELL:-$root_dir/build/ci/bin/klde-shell}}
kwin_bin=${KWIN_WAYLAND_BIN:-kwin_wayland}
app_command=${OWODE_APP:-${LOMODE_APP:-}}
session_mode=${OWODE_MODE:-${LOMODE_MODE:-preview}}

if ! command -v dbus-run-session >/dev/null 2>&1; then
    echo "owoDE session: dbus-run-session is required." >&2
    exit 2
fi
if ! command -v "$kwin_bin" >/dev/null 2>&1; then
    echo "owoDE session: $kwin_bin is not installed; refusing to touch the host session." >&2
    exit 3
fi
if [[ ! -x "$shell_bin" ]]; then
    echo "owoDE session: shell binary not found at $shell_bin." >&2
    echo "Set OWODE_SHELL (or legacy LOMODE_SHELL) to a cloud-built klde-shell binary." >&2
    exit 4
fi

exec dbus-run-session -- bash -s -- "$kwin_bin" "$shell_bin" "$app_command" "$session_mode" <<'INNER'
set -euo pipefail
kwin_bin=$1
shell_bin=$2
app_command=$3
session_mode=$4
runtime_dir=${XDG_RUNTIME_DIR:?dbus-run-session did not provide XDG_RUNTIME_DIR}
# Every invocation owns a unique socket name. Never remove a socket that this
# process did not create, and never assume the historical wayland-2 name.
socket_name="owode-wayland-${$}-${RANDOM}"
help_text=$($kwin_bin --help 2>&1 || true)

has_flag() { grep -Eq -- "$1" <<<"$help_text"; }
if has_flag '--socket'; then
    args=(--socket="$socket_name")
elif has_flag '--wayland-display'; then
    args=(--wayland-display="$socket_name")
else
    echo "KWin does not advertise a named Wayland socket option; refusing to guess." >&2
    exit 5
fi
has_flag '--virtual' && args+=(--virtual)
has_flag '--xwayland' && args+=(--xwayland)
has_flag '--no-global-shortcuts' && args+=(--no-global-shortcuts)
has_flag '--exit-with-session' && args+=(--exit-with-session)

export XDG_CURRENT_DESKTOP=owoDE
export XDG_SESSION_DESKTOP=owoDE
export WAYLAND_DISPLAY="$socket_name"
kwin_log=${OWODE_SESSION_LOG:-${LOMODE_SESSION_LOG:-/tmp/owode-kwin.log}}

cleanup() {
    if [[ -n "${app_pid:-}" ]] && kill -0 "$app_pid" 2>/dev/null; then kill "$app_pid" 2>/dev/null || true; fi
    if [[ -n "${shell_pid:-}" ]] && kill -0 "$shell_pid" 2>/dev/null; then kill "$shell_pid" 2>/dev/null || true; fi
    if [[ -n "${kwin_pid:-}" ]] && kill -0 "$kwin_pid" 2>/dev/null; then kill "$kwin_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

echo "Starting isolated KWin: $kwin_bin ${args[*]}"
"$kwin_bin" "${args[@]}" >"$kwin_log" 2>&1 &
kwin_pid=$!
for _ in $(seq 1 100); do
    [[ -S "$runtime_dir/$socket_name" ]] && break
    kill -0 "$kwin_pid" 2>/dev/null || {
        echo "KWin exited before creating $socket_name; log: $kwin_log" >&2
        tail -80 "$kwin_log" >&2 || true
        exit 6
    }
    sleep 0.1
done
[[ -S "$runtime_dir/$socket_name" ]] || {
    echo "Timed out waiting for isolated Wayland socket; log: $kwin_log" >&2
    tail -80 "$kwin_log" >&2 || true
    exit 7
}

echo "Starting owoDE shell on $WAYLAND_DISPLAY (mode: $session_mode)"
shell_args=(--view desktop)
if [[ "$session_mode" == "native" ]]; then
    shell_args=(--native-shell-surfaces)
elif [[ "$session_mode" != "preview" ]]; then
    echo "Unsupported OWODE_MODE/LOMODE_MODE: $session_mode" >&2
    exit 8
fi
XCURSOR_THEME=${XCURSOR_THEME:-Bibata-Modern-Classic} \
XCURSOR_SIZE=${XCURSOR_SIZE:-24} \
QT_QPA_PLATFORM=wayland "$shell_bin" "${shell_args[@]}" &
shell_pid=$!

if [[ -n "$app_command" ]]; then
    echo "Starting genuine application: $app_command"
    XCURSOR_THEME=${XCURSOR_THEME:-Bibata-Modern-Classic} \
    XCURSOR_SIZE=${XCURSOR_SIZE:-24} \
    WAYLAND_DISPLAY="$socket_name" sh -lc "$app_command" &
    app_pid=$!
else
    echo "No application started. Re-run with OWODE_APP='your-desktop-app-or-command'."
fi

wait "$shell_pid"
INNER
