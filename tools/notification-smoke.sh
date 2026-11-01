#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Cloud-only real notification -> real native ribbon; never use the host bus.
set -euo pipefail
[[ "${OWODE_CLOUD_NOTIFICATION_TEST:-0}" == 1 && -f /.dockerenv ]] || exit 2
build_dir="$(realpath "${1:?Pass the cloud-built CMake tree}")"
out_dir="${2:-artifacts/notifications-native}"
mkdir -p "$out_dir"
out_dir="$(realpath "$out_dir")"
runtime_dir="$(mktemp -d /tmp/owode-notifications-XXXXXX)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
mkdir -p "$runtime_dir/config" "$runtime_dir/data" "$runtime_dir/cache"
cp "$(command -v kwin_wayland)" "$runtime_dir/kwin_wayland"
chmod 700 "$runtime_dir/kwin_wayland"
xvfb-run -a -s '-screen 0 1960x1160x24 -nolisten tcp' \
 env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config" \
 XDG_DATA_HOME="$runtime_dir/data" XDG_CACHE_HOME="$runtime_dir/cache" LIBGL_ALWAYS_SOFTWARE=1 \
 dbus-run-session -- bash -s -- "$build_dir" "$out_dir" <<'INNER'
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
"$XDG_RUNTIME_DIR/kwin_wayland" --x11-display "$DISPLAY" --socket owode-notifications \
 --width 1920 --height 1080 --no-global-shortcuts > "$out_dir/kwin.log" 2>&1 &
kwin_pid=$!
for _ in $(seq 1 150); do
    [[ -S "$XDG_RUNTIME_DIR/owode-notifications" ]] && break
    kill -0 "$kwin_pid"
    sleep .1
done
test -S "$XDG_RUNTIME_DIR/owode-notifications"
WAYLAND_DISPLAY=owode-notifications XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=owoDE \
 QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software WAYLAND_DEBUG=client \
 "$build_dir/bin/klde-shell" --native-shell-surfaces --applications system --locale zh_CN \
 > "$out_dir/shell.log" 2>&1 &
shell_pid=$!
python3 tools/wait-native-buffers.py "$out_dir/shell.log" "$out_dir/first-buffers.json" --roles wallpaper ribbon dock
python3 - "$out_dir" <<'PY'
import dbus
import json
from pathlib import Path
import sys
import time
output = Path(sys.argv[1])
bus = dbus.SessionBus()
for _ in range(100):
    if bus.name_has_owner('org.freedesktop.Notifications'):
        break
    time.sleep(.1)
else:
    raise SystemExit('Native shell did not register the notification service')
locker = dbus.Interface(bus.get_object('org.freedesktop.ScreenSaver','/ScreenSaver'), 'org.freedesktop.ScreenSaver')
assert not locker.GetActive(), 'The isolated test must remain unlocked'
server = dbus.Interface(bus.get_object('org.freedesktop.Notifications','/org/freedesktop/Notifications'),'org.freedesktop.Notifications')
assert tuple(server.GetServerInformation())[0] == 'owoDE'
# Finish initial layout before comparing the steady exclusive zone.
time.sleep(1)
offset = (output / 'shell.log').stat().st_size
identifier = server.Notify('owoDE Cloud Fixture',0,'dialog-information','云端通知已送达','这条通知通过真实 D-Bus 到达原生顶栏。',[],{'urgency':dbus.Byte(2)},0)
(output / 'request.json').write_text(json.dumps({'notificationId':int(identifier),'logOffsetBeforeNotify':offset,'server':'owoDE','lockerActive':False},indent=2)+'\n')
time.sleep(1)
PY
magick import -window root "$out_dir/island-native.png"
python3 - "$out_dir" <<'PY'
import dbus
import json
from pathlib import Path
import sys
import time
output = Path(sys.argv[1])
request = json.loads((output/'request.json').read_text())
server = dbus.Interface(dbus.SessionBus().get_object('org.freedesktop.Notifications','/org/freedesktop/Notifications'),'org.freedesktop.Notifications')
server.CloseNotification(dbus.UInt32(request['notificationId']))
time.sleep(1)
PY
magick import -window root "$out_dir/after-close-native.png"
kill -0 "$shell_pid"
INNER
python3 - "$out_dir" <<'PY'
import json
from pathlib import Path
import re
import sys
output = Path(sys.argv[1])
request = json.loads((output/'request.json').read_text())
raw = (output/'shell.log').read_bytes()
before = raw[:request['logOffsetBeforeNotify']].decode(errors='replace')
after = raw[request['logOffsetBeforeNotify']:].decode(errors='replace')
pattern = r'zwlr_layer_surface_v1[@#](\d+)\.set_exclusive_zone\((\d+)\)'
previous = dict(re.findall(pattern,before))
changes = re.findall(pattern,after)
assert previous, 'No exclusive-zone protocol evidence'
assert all(previous.get(surface)==zone for surface,zone in changes), 'Notification changed a reserved exclusive zone'
ribbons = re.findall(r'zwlr_layer_surface_v1[@#](\d+)\.set_anchor\(13\)', before)
assert len(ribbons) == 1, 'Expected one primary top ribbon'
ribbon = re.escape(ribbons[0])
sizes = r'zwlr_layer_surface_v1[@#]' + ribbon + r'\.set_size\(\d+, (\d+)\)'
resting = int(re.findall(sizes, before)[-1])
heights = [int(height) for height in re.findall(sizes, after)]
assert heights and max(heights) > resting, 'No real native ribbon expansion observed'
assert heights[-1] == resting, 'Native ribbon did not return to its resting height'
for marker in ('ReferenceError:','TypeError:','is not a type','Cannot assign to'):
    assert marker not in raw.decode(errors='replace'), marker
(output/'summary.json').write_text(json.dumps({
 'server':'owoDE','nativeSystemMode':True,'isolatedBus':True,
 'notificationId':request['notificationId'],'exclusiveZonesUnchanged':True,
 'restingRibbonHeight':resting,'maximumExpandedHeight':max(heights),
 'softwareRendering':True,'hardwarePerformanceBenchmark':False,
 'realSessionLocked':False,'scope':'Real D-Bus notification and close, native ribbon protocol and screenshots',
},indent=2)+'\n')
print('Native notification delivered and closed; resting exclusive zone unchanged')
PY
