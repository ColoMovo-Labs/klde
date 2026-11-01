#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Cloud-only: greeter presentation loading, never a lock of the user's session.
set -euo pipefail
[[ "${OWODE_CLOUD_LOCKER_TEST:-0}" == 1 ]] || {
    echo 'Run only in an isolated cloud container with OWODE_CLOUD_LOCKER_TEST=1.' >&2
    exit 2
}
build_dir="$(realpath "${1:?Pass the cloud-built CMake tree}")"
out_dir="${2:-artifacts/locker-theme}"
mkdir -p "$out_dir"
out_dir="$(realpath "$out_dir")"
runtime_dir="$(mktemp -d /tmp/owode-locker-ci-XXXXXX)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
mkdir -p "$runtime_dir/config" "$runtime_dir/data" "$runtime_dir/cache"
cmake --install "$build_dir" --prefix "$runtime_dir/install" > "$out_dir/install.log"
# Deliberately break ONLY the private test prefix to exercise the Loader's
# minimal KDE Greeter fallback. Installed files and the host are untouched.
if [[ "${OWODE_LOCKER_FORCE_FALLBACK:-0}" == 1 ]]; then
    printf 'import QtQuick\nItem { __owode_missing_test_property__: true }\n' \
        > "$runtime_dir/install/share/plasma/shells/org.owode.shell/contents/lockscreen/OwoLockScreen.qml"
fi
cp "$(command -v kwin_wayland)" "$runtime_dir/kwin_wayland"
chmod 700 "$runtime_dir/kwin_wayland"
greeter=/usr/libexec/kscreenlocker_greet
test -x "$greeter"
rpm -q kwin kscreenlocker plasma-workspace-libs > "$out_dir/versions.txt"
xvfb-run -a -s '-screen 0 1440x900x24 -nolisten tcp' \
    env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$runtime_dir" \
    XDG_CONFIG_HOME="$runtime_dir/config" XDG_DATA_HOME="$runtime_dir/data" \
    XDG_DATA_DIRS="$runtime_dir/install/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" \
    PLASMA_DEFAULT_SHELL=org.owode.shell \
    XDG_CACHE_HOME="$runtime_dir/cache" LIBGL_ALWAYS_SOFTWARE=1 \
    dbus-run-session -- bash -s -- "$out_dir" "$greeter" <<'INNER'
set -euo pipefail
out_dir=$1
greeter=$2
kwin_pid=
greeter_pid=
cleanup() {
    for pid in "$greeter_pid" "$kwin_pid"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid"
            wait "$pid" || true
        fi
    done
}
trap cleanup EXIT
"$XDG_RUNTIME_DIR/kwin_wayland" --x11-display "$DISPLAY" --socket owode-locker-ci \
    --width 1440 --height 900 --no-global-shortcuts > "$out_dir/kwin.log" 2>&1 &
kwin_pid=$!
for _ in $(seq 1 150); do
    [[ -S "$XDG_RUNTIME_DIR/owode-locker-ci" ]] && break
    kill -0 "$kwin_pid" 2>/dev/null || { cat "$out_dir/kwin.log"; exit 1; }
    sleep 0.1
done
test -S "$XDG_RUNTIME_DIR/owode-locker-ci"
env WAYLAND_DISPLAY=owode-locker-ci QT_QPA_PLATFORM=wayland \
    QT_QUICK_BACKEND=software QT_FORCE_STDERR_LOGGING=1 WAYLAND_DEBUG=client \
    "$greeter" --testing --immediateLock \
    --shell "$XDG_RUNTIME_DIR/install/share/plasma/shells/org.owode.shell" \
    > "$out_dir/greeter.log" 2>&1 &
greeter_pid=$!
for _ in $(seq 1 100); do
    kill -0 "$greeter_pid" 2>/dev/null || { cat "$out_dir/greeter.log"; exit 1; }
    if grep -Eq 'wl_surface[@#][0-9]+\.attach\(wl_buffer' "$out_dir/greeter.log"; then break; fi
    sleep 0.1
done
sleep 2
kill -0 "$greeter_pid"
# This is the private Xvfb display created above, not the host screen.
magick import -window root "$out_dir/greeter.png"
python3 - "$out_dir" <<'PY'
import json
import os
from pathlib import Path
import re
import sys
output = Path(sys.argv[1])
log = (output / 'greeter.log').read_text(errors='replace')
expected_fallback = os.environ.get('OWODE_LOCKER_FORCE_FALLBACK') == '1'
fallback_used = 'custom locker appearance failed; using KDE Greeter' in log
if fallback_used != expected_fallback:
    raise SystemExit(f'Unexpected locker fallback: expected={expected_fallback}, used={fallback_used}')
scan_log = log.replace('Cannot assign to non-existent property "__owode_missing_test_property__"', '') if expected_fallback else log
for error in ('is not installed', 'QML outdated',
              'ReferenceError:', 'TypeError:', 'is not a type', 'Cannot assign to'):
    if error in scan_log:
        raise SystemExit(f'Greeter loading failed: {error}')
if not expected_fallback and ('Failed to load' in log or 'fallbacktheme' in log):
    raise SystemExit('Unexpected greeter loading failure')
if 'Failed to load the fallback' in log or 'falling back to built-in locker' in log:
    raise SystemExit('Built-in fallback failed to load')
attached = re.findall(r'wl_surface[@#](\d+)\.attach\(wl_buffer', log)
committed = [surface for surface in set(attached)
             if re.search(r'wl_surface[@#]' + surface + r'\.commit\(', log)]
if not committed:
    raise SystemExit('No real greeter buffer committed to the isolated KWin')
(output / 'summary.json').write_text(json.dumps({
    'theme': 'org.owode.shell', 'testingMode': True,
    'nativeBufferSurfaces': committed, 'fallbackUsed': fallback_used,
    'brokenPrivateThemeTest': expected_fallback,
    'pamUnlockTested': False, 'realSessionLocked': False,
    'scope': 'QML import, package API and native rendering only',
}, indent=2) + '\n')
print('Greeter: native buffer committed; fallback=' + str(fallback_used) + '; PAM not tested')
PY
INNER
