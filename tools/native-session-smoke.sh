#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
build_dir="$(realpath "${1:?Pass the cloud-built CMake tree}")"
out_dir="${2:-artifacts/native-session}"
mkdir -p "$out_dir"
out_dir="$(realpath "$out_dir")"
runtime_dir="$(mktemp -d /tmp/owode-native-ci-XXXXXX)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
kwin_source="$(command -v kwin_wayland)"
# Distribution file capabilities can make exec fail in restricted containers.
# Copy only bytes, never privilege xattrs, and leave the system binary intact.
python3 - "$kwin_source" "$runtime_dir/kwin_wayland" "$out_dir" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
source, target, output = map(Path, sys.argv[1:])
shutil.copyfile(source, target)
target.chmod(0o700)
if 'security.capability' in os.listxattr(target):
    raise SystemExit('The private test copy must not carry file capabilities')
digest = hashlib.sha256(source.read_bytes()).hexdigest()
if hashlib.sha256(target.read_bytes()).hexdigest() != digest:
    raise SystemExit('KWin copy differs from the distribution binary')
(output / 'kwin-binary.json').write_text(json.dumps({
    'distributionBinary': str(source), 'sha256': digest,
    'privateCopyHasFileCapabilities': False,
    'distributionBinaryModified': False,
    'hardwarePerformanceBenchmark': False,
}, indent=2) + '\n')
PY
mkdir -p "$runtime_dir/config/menus" "$runtime_dir/cache" "$runtime_dir/data/applications"
# KWin authorizes restricted interfaces through the executable's desktop entry.
# Only this test client requests input injection, in this private data directory.
cat > "$runtime_dir/data/applications/org.owode.NativeAudit.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=owoDE isolated native test
Exec=$build_dir/bin/klde-native-session-test
NoDisplay=true
X-KDE-Wayland-Interfaces=org_kde_kwin_fake_input
EOF
cat > "$runtime_dir/data/applications/org.owode.NativeCapture.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=owoDE isolated compositor capture
Exec=$build_dir/bin/owode-native-capture
NoDisplay=true
X-KDE-DBUS-Restricted-Interfaces=org.kde.KWin.ScreenShot2
EOF
# Minimal images have no desktop menu package. Give KService an explicit menu
# containing only this private test application's metadata.
cat > "$runtime_dir/config/menus/applications.menu" <<EOF
<Menu>
  <Name>Applications</Name>
  <AppDir>$runtime_dir/data/applications</AppDir>
  <Include><All/></Include>
</Menu>
EOF
# These bindings exist only in this runner's private config, never on the host.
cat > "$runtime_dir/config/kwinrc" <<'EOF'
[MouseBindings]
CommandAllKey=Meta
CommandAll1=Move
EOF
cat > "$runtime_dir/config/kdeglobals" <<'EOF'
[KDE]
AnimationDurationFactor=0
EOF
git rev-parse HEAD > "$out_dir/source-commit.txt"
xvfb-run -a -s '-screen 0 1600x1000x24 -nolisten tcp' \
    env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$runtime_dir" \
    XDG_CONFIG_HOME="$runtime_dir/config" XDG_CACHE_HOME="$runtime_dir/cache" \
    XDG_DATA_HOME="$runtime_dir/data" LIBGL_ALWAYS_SOFTWARE=1 \
    OWODE_KWIN_BIN="$runtime_dir/kwin_wayland" \
    OWODE_NATIVE_TEST_ISOLATED=1 OWODE_NATIVE_EVIDENCE="$out_dir" \
    dbus-run-session -- bash -s -- "$build_dir" "$out_dir" <<'INNER'
set -euo pipefail
build_dir=$1
out_dir=$2
kwin_pid=
shell_pid=
kbuildsycoca6 --noincremental > "$out_dir/desktop-cache.log" 2>&1
cleanup() {
    if [[ -n "$shell_pid" ]] && kill -0 "$shell_pid" 2>/dev/null; then
        kill -TERM "$shell_pid"
        wait "$shell_pid" || true
    fi
    if [[ -n "$kwin_pid" ]] && kill -0 "$kwin_pid" 2>/dev/null; then
        kill -TERM "$kwin_pid"
        wait "$kwin_pid" || true
    fi
}
trap cleanup EXIT
"$OWODE_KWIN_BIN" --version > "$out_dir/kwin-version.txt" 2>&1
QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_TO_CONSOLE=1 \
QT_LOGGING_RULES='kwin_core.debug=true;KWIN_UTILS.debug=true' \
"$OWODE_KWIN_BIN" --x11-display "$DISPLAY" --socket owode-ci --width 1600 --height 1000 \
    --no-global-shortcuts > "$out_dir/kwin.log" 2>&1 &
kwin_pid=$!
for _ in $(seq 1 150); do
    [[ -S "$XDG_RUNTIME_DIR/owode-ci" ]] && break
    kill -0 "$kwin_pid" 2>/dev/null || { cat "$out_dir/kwin.log"; exit 1; }
    sleep 0.1
done
test -S "$XDG_RUNTIME_DIR/owode-ci"
# X11 readback is permitted only for the viewport owned by this isolated KWin.
# The capture helper independently matches its PID against the private D-Bus owner.
for _ in $(seq 1 100); do
    viewport=$(xdotool search --onlyvisible --pid "$kwin_pid" 2>/dev/null | head -1 || true)
    [[ -n "$viewport" ]] && break
    sleep 0.1
done
[[ -n "$viewport" ]]
export OWODE_NATIVE_CAPTURE_WINDOW="$viewport"
printf '%s %s\n' "$kwin_pid" "$viewport" > "$out_dir/owned-viewport.txt"
export WAYLAND_DISPLAY=owode-ci XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=owoDE
if ! timeout 180s env QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software WAYLAND_DEBUG=client \
    "$build_dir/bin/klde-native-session-test" -o "$out_dir/native-tests.xml,junitxml" -o -,txt \
    > "$out_dir/native-test.log" 2>&1; then
    tail -100 "$out_dir/native-test.log"
    exit 1
fi
# Also launch the real CLI, rather than inferring main.cpp behavior from the test.
env -u QT_QUICK_BACKEND QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=wayland QSG_RHI_BACKEND=opengl WAYLAND_DEBUG=client \
    "$build_dir/bin/klde-shell" --native-shell-surfaces --view quick-settings \
    > "$out_dir/native-main.log" 2>&1 &
shell_pid=$!
sleep 3
kill -0 "$shell_pid"
"$build_dir/bin/owode-native-capture" "$out_dir/native-main.png"
kill -TERM "$shell_pid"
wait "$shell_pid" || [[ $? == 143 ]]
shell_pid=
python3 tools/verify-native-protocol.py "$out_dir"
kill -TERM "$kwin_pid"
kwin_status=0
wait "$kwin_pid" || kwin_status=$?
# KWin forwards the handled signal number to QCoreApplication::exit (15).
[[ "$kwin_status" == 0 || "$kwin_status" == 15 ]]
printf '%s\n' "$kwin_status" > "$out_dir/kwin-stop-status.txt"
kwin_pid=
test ! -S "$XDG_RUNTIME_DIR/owode-ci"
printf '%s\n' 'Owned KWin and shell processes exited; private Wayland socket removed.' > "$out_dir/shutdown.txt"
INNER
