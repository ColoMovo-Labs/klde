#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Executed by the isolated CI KWin through the same exit-with-session contract.
set -euo pipefail
[[ "${OWODE_NATIVE_TEST_ISOLATED:-}" == 1 && "$XDG_RUNTIME_DIR" == /tmp/owode-login-ci-* ]] || exit 2
shell_pid=; wayland_pid=; x11_pid=; gnome_pid=; kde_pid=
cleanup() {
    for pid in "$shell_pid" "$wayland_pid" "$x11_pid" "$gnome_pid" "$kde_pid"; do
        [[ -z "$pid" ]] || kill -TERM "$pid" 2>/dev/null || true
    done
    wait || true
}
trap cleanup EXIT
trap 'exit 143' TERM
/usr/libexec/owode-session-client > "$OWODE_SESSION_EVIDENCE/shell.log" 2>&1 &
shell_pid=$!
for _ in $(seq 1 150); do
    if dbus-send --session --print-reply --dest=org.owode.Session /org/owode/Session \
        org.freedesktop.DBus.Introspectable.Introspect > "$OWODE_SESSION_EVIDENCE/session-interface.xml" 2>/dev/null; then break; fi
    kill -0 "$shell_pid"
    sleep 0.1
done
grep -q org.owode.Session1 "$OWODE_SESSION_EVIDENCE/session-interface.xml"
python3 tools/wait-native-buffers.py "$OWODE_SESSION_EVIDENCE/shell.log" "$OWODE_SESSION_EVIDENCE/first-buffers.json"
# These are genuine toolkit clients. Xwayland's DISPLAY is supplied by KWin,
# rather than inherited from the Xvfb parent used only for the nested viewport.
[[ -n "${DISPLAY:-}" && "$DISPLAY" != "$OWODE_SESSION_PARENT_DISPLAY" ]]
env QT_QPA_PLATFORM=wayland "$OWODE_SESSION_BUILD/bin/owode-native-test-client" \
    --state "$OWODE_SESSION_EVIDENCE/wayland-client.json" > "$OWODE_SESSION_EVIDENCE/wayland-client.log" 2>&1 &
wayland_pid=$!
env QT_QPA_PLATFORM=xcb "$OWODE_SESSION_BUILD/bin/owode-native-test-client" \
    --state "$OWODE_SESSION_EVIDENCE/x11-client.json" > "$OWODE_SESSION_EVIDENCE/x11-client.log" 2>&1 &
x11_pid=$!
for _ in $(seq 1 100); do
    [[ ! -s "$OWODE_SESSION_EVIDENCE/wayland-client.json" || ! -s "$OWODE_SESSION_EVIDENCE/x11-client.json" ]] || break
    kill -0 "$wayland_pid"; kill -0 "$x11_pid"
    sleep 0.1
done
python3 - "$OWODE_SESSION_EVIDENCE" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
for name, platform in [('wayland', 'wayland'), ('x11', 'xcb')]:
    state = json.loads((root / f'{name}-client.json').read_text())
    assert state['platform'] == platform, state
    assert state['width'] > 0 and state['height'] > 0, state
print('Installed native shell + real Wayland and Xwayland clients started.')
PY
# Check actual distribution GTK/libadwaita and KDE/Qt apps, not just a Qt fixture.
script_id=$(dbus-send --session --print-reply --dest=org.kde.KWin /Scripting \
    org.kde.kwin.Scripting.loadScript "string:$PWD/tests/session/compatibility.js" \
    string:owode-session-compatibility | awk '/int32/ { print $2 }')
[[ "$script_id" =~ ^[0-9]+$ ]]
dbus-send --session --print-reply --dest=org.kde.KWin \
    "/Scripting/Script$script_id" org.kde.kwin.Script.run > "$OWODE_SESSION_EVIDENCE/script.txt"
env GDK_BACKEND=wayland /usr/bin/owode-run --gnome -- gnome-calculator \
    > "$OWODE_SESSION_EVIDENCE/gnome-calculator.log" 2>&1 &
gnome_pid=$!
env QT_QPA_PLATFORM=wayland /usr/bin/owode-run --kde -- kcalc \
    > "$OWODE_SESSION_EVIDENCE/kcalc.log" 2>&1 &
kde_pid=$!
python3 - "$OWODE_SESSION_EVIDENCE" <<'PY'
import json, sys, time
from pathlib import Path
root = Path(sys.argv[1])
deadline = time.monotonic() + 20
while time.monotonic() < deadline:
    for line in (root / 'kwin.log').read_text(errors='replace').splitlines():
        if 'OWODE_COMPAT_WINDOWS:' not in line:
            continue
        windows = json.loads(line.split('OWODE_COMPAT_WINDOWS:', 1)[1])
        apps = [w for w in windows if w['normal']]
        names = [w['appId'].lower() for w in apps]
        if (any('gnome.calculator' in n or 'gnome-calculator' in n for n in names)
                and any('kcalc' in n for n in names)):
            (root / 'compatibility-windows.json').write_text(json.dumps(windows, indent=2) + '\n')
            sys.exit(0)
    time.sleep(.1)
raise SystemExit('KWin did not report both actual GNOME Calculator and KCalc windows')
PY
kwin_pid=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.GetConnectionUnixProcessID string:org.kde.KWin | awk '/uint32/ {print $2}')
viewport=$(DISPLAY="$OWODE_SESSION_PARENT_DISPLAY" xdotool search --onlyvisible --pid "$kwin_pid" | head -1)
[[ -n "$viewport" ]]
env DISPLAY="$OWODE_SESSION_PARENT_DISPLAY" OWODE_NATIVE_CAPTURE_WINDOW="$viewport" \
    "$OWODE_SESSION_BUILD/bin/owode-native-capture" "$OWODE_SESSION_EVIDENCE/installed-session-apps.png"
rpm -q kwin layer-shell-qt gnome-calculator kcalc > "$OWODE_SESSION_EVIDENCE/packages.txt"
# Logout must be handled by our session service, not loginctl/system shutdown.
dbus-send --session --print-reply --dest=org.owode.Session /org/owode/Session \
    org.owode.Session1.logout > "$OWODE_SESSION_EVIDENCE/logout.txt"
grep -q 'boolean true' "$OWODE_SESSION_EVIDENCE/logout.txt"
wait "$shell_pid"
shell_pid=
printf '%s\n' 'Installed shell exited normally after owned-session logout.' > "$OWODE_SESSION_EVIDENCE/lifecycle.txt"
