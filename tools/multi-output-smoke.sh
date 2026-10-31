#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Cloud-only: start the native shell in a private nested KWin with two outputs
# and check that every output gets a wallpaper while the top bar and dock stay
# on one output. Nothing here touches the host session.
set -euo pipefail
build_dir="$(realpath "${1:?Pass the cloud-built CMake tree}")"
out_dir="${2:-artifacts/multi-output}"
mkdir -p "$out_dir"
out_dir="$(realpath "$out_dir")"
runtime_dir="$(mktemp -d /tmp/owode-multi-output-XXXXXX)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
# Distribution file capabilities can make exec fail in restricted containers.
cp "$(command -v kwin_wayland)" "$runtime_dir/kwin_wayland"
chmod 700 "$runtime_dir/kwin_wayland"
mkdir -p "$runtime_dir/config" "$runtime_dir/cache" "$runtime_dir/data"
printf '[KDE]\nAnimationDurationFactor=0\n' > "$runtime_dir/config/kdeglobals"
xvfb-run -a -s '-screen 0 2600x900x24 -nolisten tcp' env -u WAYLAND_DISPLAY \
    XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config" \
    XDG_CACHE_HOME="$runtime_dir/cache" XDG_DATA_HOME="$runtime_dir/data" \
    LIBGL_ALWAYS_SOFTWARE=1 dbus-run-session -- bash -s -- "$build_dir" "$out_dir" <<'INNER'
set -euo pipefail
build_dir=$1
out_dir=$2
kwin_pid=
shell_pid=
cleanup() {
    for pid in "$shell_pid" "$kwin_pid"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid"
            wait "$pid" || true
        fi
    done
}
trap cleanup EXIT
"$XDG_RUNTIME_DIR/kwin_wayland" --version > "$out_dir/kwin-version.txt" 2>&1
"$XDG_RUNTIME_DIR/kwin_wayland" --x11-display "$DISPLAY" --socket owode-multi \
    --output-count 2 --width 1280 --height 800 --no-global-shortcuts \
    > "$out_dir/kwin.log" 2>&1 &
kwin_pid=$!
for _ in $(seq 1 150); do
    [[ -S "$XDG_RUNTIME_DIR/owode-multi" ]] && break
    kill -0 "$kwin_pid" 2>/dev/null || { cat "$out_dir/kwin.log"; exit 1; }
    sleep 0.1
done
test -S "$XDG_RUNTIME_DIR/owode-multi"
WAYLAND_DISPLAY=owode-multi XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=owoDE \
    QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software WAYLAND_DEBUG=client \
    QT_FORCE_STDERR_LOGGING=1 \
    "$build_dir/bin/klde-shell" --native-shell-surfaces --applications mock \
    > "$out_dir/shell.log" 2>&1 &
shell_pid=$!
python3 tools/wait-native-buffers.py "$out_dir/shell.log" "$out_dir/first-buffers.json" \
    --roles wallpaper ribbon dock
kill -0 "$shell_pid"
INNER
python3 - "$out_dir/shell.log" "$out_dir/summary.json" <<'PY'
import json
import re
import sys

log = open(sys.argv[1], errors='replace').read()
created = re.findall(
    r'get_layer_surface\(new id zwlr_layer_surface_v1[@#]\d+, wl_surface[@#]\d+, '
    r'(wl_output[@#]\d+|nil), \d+, "(desktop|dock|on-screen-display)"\)', log)
wallpapers = [output for output, namespace in created if namespace == 'desktop']
bars = [output for output, namespace in created if namespace == 'dock']
summary = {'wallpaperOutputs': wallpapers, 'barOutputs': bars}
open(sys.argv[2], 'w').write(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary))
if len(set(wallpapers)) != 2 or 'nil' in wallpapers:
    raise SystemExit('Expected one wallpaper layer surface on each of the two outputs')
if len(bars) != 2 or len(set(bars)) != 1 or bars[0] not in wallpapers:
    raise SystemExit('Expected the top bar and dock together on a single output')
print('multi-output: two wallpapers, top bar and dock on the primary output only')
PY
