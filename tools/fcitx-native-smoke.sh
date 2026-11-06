#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
[[ "${OWODE_CLOUD_FCITX_TEST:-0}" == 1 && -f /.dockerenv ]] || exit 2
build_dir=$(realpath "${1:?Cloud build tree}")
out_dir=$(realpath -m "${2:-artifacts/fcitx-native}")
mkdir -p "$out_dir"
runtime_dir=$(mktemp -d /tmp/owode-input-ci-XXXXXX)
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
mkdir -p "$runtime_dir/config/fcitx5" "$runtime_dir/data" "$runtime_dir/cache"
# Synthetic test preferences only. Never overwrite the owner's Fcitx profile.
cat > "$runtime_dir/config/fcitx5/profile" <<'PROFILE'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=pinyin
[Groups/0/Items/0]
Name=keyboard-us
Layout=
[Groups/0/Items/1]
Name=pinyin
Layout=
[GroupOrder]
0=Default
PROFILE
cp "$(command -v kwin_wayland)" "$runtime_dir/kwin_wayland"
cp packaging/session/owode-input-method "$runtime_dir/input-method"
chmod 700 "$runtime_dir/kwin_wayland" "$runtime_dir/input-method"
"$runtime_dir/input-method" --check > "$out_dir/launcher.txt"
rpm -q kwin fcitx5 qt6-qtbase layer-shell-qt > "$out_dir/versions.txt"
cat > "$runtime_dir/client" <<'CLIENT'
#!/usr/bin/env bash
set -euo pipefail
dbus-update-activation-environment "DISPLAY=${DISPLAY:-}" "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" \
    XDG_CURRENT_DESKTOP=owoDE XDG_SESSION_TYPE=wayland XMODIFIERS=@im=fcitx
exec env QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software WAYLAND_DEBUG=client \
    "$OWODE_INPUT_BUILD/bin/owode-fcitx-native-test" \
    -o "$OWODE_INPUT_EVIDENCE/test-results.xml,junitxml" -o -,txt \
    > "$OWODE_INPUT_EVIDENCE/test.log" 2>&1
CLIENT
chmod 700 "$runtime_dir/client"
# KWin's X11 nested keyboard is unnamed; an unset skip list contains an empty
# name, unintentionally bypassing its input-method grab. Test-only sentinel:
# never set this in the production DRM login entry.
xvfb-run -a -s '-screen 0 1640x1080x24 -nolisten tcp' \
 env -u WAYLAND_DISPLAY -u GTK_IM_MODULE -u QT_IM_MODULE -u QT_IM_MODULES -u SDL_IM_MODULE \
 XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config" XDG_DATA_HOME="$runtime_dir/data" \
 XDG_CACHE_HOME="$runtime_dir/cache" LIBGL_ALWAYS_SOFTWARE=1 OWODE_MANAGED_SESSION=1 \
 KWIN_DEVICE_SKIPS_INPUT_METHOD=owode-cloud-no-such-device \
 OWODE_INPUT_BUILD="$build_dir" OWODE_INPUT_EVIDENCE="$out_dir" OWODE_CLOUD_FCITX_TEST=1 \
 XDG_CURRENT_DESKTOP=owoDE XDG_SESSION_TYPE=wayland XMODIFIERS=@im=fcitx WAYLAND_DEBUG=client \
 dbus-run-session -- bash -c '
    set -euo pipefail
    export OWODE_INPUT_PARENT_DISPLAY="$DISPLAY"
    cleanup_input() {
        # A unique owner cannot accidentally activate a new daemon during cleanup.
        fcitx_owner=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus \
            /org/freedesktop/DBus org.freedesktop.DBus.GetNameOwner string:org.fcitx.Fcitx5 \
            2>/dev/null | awk '\''/string/ {gsub(/"/, "", $2); print $2}'\'' || true)
        if [[ "$fcitx_owner" == :* ]]; then
            dbus-send --session --print-reply --dest="$fcitx_owner" /controller \
                org.fcitx.Fcitx.Controller1.Exit >/dev/null 2>&1 || true
        fi
        for _ in $(seq 1 30); do
            owner=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus \
                /org/freedesktop/DBus org.freedesktop.DBus.NameHasOwner string:org.fcitx.Fcitx5)
            [[ "$owner" == *"boolean true"* ]] || break
            sleep .1
        done
    }
    trap cleanup_input EXIT
    timeout --signal=TERM --kill-after=5s 70s "$XDG_RUNTIME_DIR/kwin_wayland" \
        --x11-display "$DISPLAY" --socket owode-input-ci --width 1600 --height 1000 \
        --inputmethod "$XDG_RUNTIME_DIR/input-method" --no-global-shortcuts \
        --exit-with-session "$XDG_RUNTIME_DIR/client" > "$OWODE_INPUT_EVIDENCE/kwin.log" 2>&1
    test ! -S "$XDG_RUNTIME_DIR/owode-input-ci"
 ' > "$out_dir/session.log" 2>&1
python3 - "$out_dir" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
state = json.loads((root / 'input-result.json').read_text())
assert state['text'] == '你好' and state['preedit'], state
assert state['methodAfterShortcut'] == 'keyboard-us', state
protocol = '\n'.join(p.read_text(errors='replace') for p in root.glob('*.log'))
assert 'zwp_input_method_v1' in protocol, 'No KWin input-method-v1 evidence'
assert 'zwp_text_input_v' in protocol, 'No native Qt text-input evidence'
print('Real KWin-launched Fcitx, Qt Wayland Pinyin commit, shortcut status update and tray verified')
PY
