#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
[[ "${CIRCLECI:-}" == true ]] || { echo 'Cloud-only installed-session integration test.' >&2; exit 2; }
build_dir=$(realpath "${1:?Cloud build tree}")
out_dir=$(realpath -m "${2:-artifacts/login-session}")
mkdir -p "$out_dir"
entry=/usr/share/wayland-sessions/owode.desktop
# Fedora desktop-file-utils 0.28 validates application entries and rejects the
# display-manager DesktopNames key. Check that session key explicitly, then
# validate every remaining key with the distribution validator.
grep -Fx 'DesktopNames=owoDE;' "$entry"
sed '/^DesktopNames=/d' "$entry" > "$out_dir/owode-entry-validation.desktop"
desktop-file-validate "$out_dir/owode-entry-validation.desktop"
grep -Fx 'Exec=/usr/bin/start-owode' /usr/share/wayland-sessions/owode.desktop
runtime_dir=$(mktemp -d /tmp/owode-login-ci-XXXXXX)
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
mkdir -p "$runtime_dir/config/menus" "$runtime_dir/data/applications" "$runtime_dir/cache"
cat > "$runtime_dir/data/applications/org.owode.NativeCapture.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=owoDE private session capture
Exec=$build_dir/bin/owode-native-capture
NoDisplay=true
X-KDE-DBUS-Restricted-Interfaces=org.kde.KWin.ScreenShot2
EOF
cat > "$runtime_dir/config/menus/applications.menu" <<EOF
<Menu><Name>Applications</Name><AppDir>$runtime_dir/data/applications</AppDir><Include><All/></Include></Menu>
EOF
# Copy bytes without distro file capabilities, only for the restricted container.
python3 - "$(command -v kwin_wayland)" "$runtime_dir/kwin_wayland" <<'PY'
from pathlib import Path
import shutil, sys
source, target = map(Path, sys.argv[1:])
shutil.copyfile(source, target)
target.chmod(0o700)
PY
env PATH="$runtime_dir:$PATH" /usr/bin/start-owode --check > "$out_dir/prerequisites.txt" 2>&1
# A graphical host must never be replaced by the login entry.
if env PATH="$runtime_dir:$PATH" WAYLAND_DISPLAY=protected-host /usr/bin/start-owode > "$out_dir/host-refusal.txt" 2>&1; then exit 1; fi
grep -q 'Refusing to start a login compositor' "$out_dir/host-refusal.txt"
printf '%s\n' "$(git rev-parse HEAD)" > "$out_dir/source-commit.txt"
xvfb-run -a -s '-screen 0 1600x1000x24 -nolisten tcp' env -u WAYLAND_DISPLAY \
    XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config" \
    XDG_DATA_HOME="$runtime_dir/data" XDG_CACHE_HOME="$runtime_dir/cache" \
    XDG_CURRENT_DESKTOP=owoDE XDG_SESSION_DESKTOP=owoDE XDG_SESSION_TYPE=wayland \
    OWODE_MANAGED_SESSION=1 OWODE_NATIVE_TEST_ISOLATED=1 \
    OWODE_SESSION_BUILD="$build_dir" OWODE_SESSION_EVIDENCE="$out_dir" \
    QT_QUICK_BACKEND=software LIBGL_ALWAYS_SOFTWARE=1 WAYLAND_DEBUG=client \
    QT_LOGGING_RULES="kwin_scripting.debug=true;js.debug=true" \
    dbus-run-session -- bash -c '
        set -euo pipefail
        export OWODE_SESSION_PARENT_DISPLAY="$DISPLAY"
        kbuildsycoca6 --noincremental > "$OWODE_SESSION_EVIDENCE/desktop-cache.log" 2>&1
        timeout --signal=TERM --kill-after=5s 60s "$XDG_RUNTIME_DIR/kwin_wayland" \
            --x11-display "$DISPLAY" --width 1600 --height 1000 \
            --socket owode-login-ci --xwayland --no-global-shortcuts \
            --exit-with-session "bash tests/session/installed-client.sh" \
            > "$OWODE_SESSION_EVIDENCE/kwin.log" 2>&1
        test ! -S "$XDG_RUNTIME_DIR/owode-login-ci"
        test -s "$OWODE_SESSION_EVIDENCE/lifecycle.txt"
        echo "Owned KWin exited normally; private Wayland socket removed." > "$OWODE_SESSION_EVIDENCE/shutdown.txt"
    '
