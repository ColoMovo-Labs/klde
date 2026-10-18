#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Start a nested KWin session without changing the host display manager/session.
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_bin=${LOMODE_SHELL:-$root_dir/build/ci/bin/klde-shell}
kwin_bin=${KWIN_WAYLAND_BIN:-kwin_wayland}
app_command=${LOMODE_APP:-}

if ! command -v dbus-run-session >/dev/null 2>&1; then
    echo "LoMoDE session: dbus-run-session is required." >&2
    exit 2
fi
if ! command -v "$kwin_bin" >/dev/null 2>&1; then
    echo "LoMoDE session: $kwin_bin is not installed; refusing to touch the host session." >&2
    exit 3
fi
if [[ ! -x "$shell_bin" ]]; then
    echo "LoMoDE session: shell binary not found at $shell_bin." >&2
    echo "Set LOMODE_SHELL to a cloud-built klde-shell binary." >&2
    exit 4
fi

exec dbus-run-session -- bash -s -- "$kwin_bin" "$shell_bin" "$app_command" <<'INNER'
set -euo pipefail
kwin_bin=$1
shell_bin=$2
app_command=$3
runtime_dir=${XDG_RUNTIME_DIR:?dbus-run-session did not provide XDG_RUNTIME_DIR}
socket_name=lomode-wayland-0
help_text=$($kwin_bin --help 2>&1 || true)

has_flag() { grep -Eq -- "$1" <<<"$help_text"; }
args=(--socket="$socket_name")
has_flag '--virtual' && args+=(--virtual)
has_flag '--xwayland' && args+=(--xwayland)
has_flag '--no-global-shortcuts' && args+=(--no-global-shortcuts)
has_flag '--exit-with-session' && args+=(--exit-with-session)

export XDG_CURRENT_DESKTOP=LoMoDE
export XDG_SESSION_DESKTOP=LoMoDE
export WAYLAND_DISPLAY="$socket_name"

cleanup() {
    if [[ -n "${app_pid:-}" ]] && kill -0 "$app_pid" 2>/dev/null; then kill "$app_pid" 2>/dev/null || true; fi
    if [[ -n "${shell_pid:-}" ]] && kill -0 "$shell_pid" 2>/dev/null; then kill "$shell_pid" 2>/dev/null || true; fi
    if [[ -n "${kwin_pid:-}" ]] && kill -0 "$kwin_pid" 2>/dev/null; then kill "$kwin_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

echo "Starting isolated KWin: $kwin_bin ${args[*]}"
"$kwin_bin" "${args[@]}" &
kwin_pid=$!
for _ in $(seq 1 100); do
    [[ -S "$runtime_dir/$socket_name" ]] && break
    kill -0 "$kwin_pid" 2>/dev/null || { echo "KWin exited before creating $socket_name" >&2; exit 5; }
    sleep 0.1
done
[[ -S "$runtime_dir/$socket_name" ]] || { echo "Timed out waiting for isolated Wayland socket" >&2; exit 6; }

echo "Starting LoMoDE shell on $WAYLAND_DISPLAY"
QT_QPA_PLATFORM=wayland "$shell_bin" --view desktop &
shell_pid=$!

if [[ -n "$app_command" ]]; then
    echo "Starting genuine application: $app_command"
    WAYLAND_DISPLAY="$socket_name" sh -lc "$app_command" &
    app_pid=$!
else
    echo "No application started. Re-run with LOMODE_APP='your-desktop-app-or-command'."
fi

wait "$shell_pid"
INNER
