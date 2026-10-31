#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Changes ONLY a disposable cloud guest carrying an unpredictable NoCloud marker.
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Guest audit requires its private root account.' >&2; exit 2; }
[[ -n ${2:-} && $(cat /etc/owode-ci-vm) == "$2" ]] || exit 2
[[ $(hostname) == owode-ci-vm ]] || { echo "Unexpected guest hostname: $(hostname)" >&2; exit 2; }
case $(systemd-detect-virt) in qemu|kvm) ;; *) echo 'Guest is not QEMU/KVM.' >&2; exit 2;; esac
[[ $(. /etc/os-release; echo "$ID:$VERSION_ID") == fedora:44 ]] || exit 2
out=/var/tmp/owode-vm-evidence
mkdir -p "$out"
collect() {
    journalctl -b --no-pager -o cat > "$out/journal.log"
    loginctl list-sessions --no-legend > "$out/sessions.txt"
    ps -eo user,pid,ppid,args > "$out/processes.txt"
    rpm -qa | sort > "$out/packages.txt"
    getenforce > "$out/selinux.txt"
}
trap collect EXIT
uid=$(id -u owodeci)
as_user() {
    runuser -u owodeci -- env XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" "$@"
}
bus() { as_user busctl --user --json=short call "$@"; }
wait_owode() {
    for _ in $(seq 1 90); do
        if bus org.owode.Session /org/owode/Session org.freedesktop.DBus.Introspectable Introspect \
            > "$out/session-interface.json" 2>/dev/null; then return; fi
        sleep 2
    done
    echo 'GDM did not start the installed owoDE session.' >&2
    return 1
}
case ${1:-} in
setup)
    dnf install -y --setopt=install_weak_deps=False \
        /tmp/owode-vm-payload/*.rpm gdm gnome-shell gnome-session \
        gnome-calculator kcalc adwaita-icon-theme breeze-icon-theme dbus-tools python3
    /usr/bin/start-owode --check > "$out/prerequisites.txt" 2>&1
    mkdir -p /usr/local/share/owode-ci /var/lib/AccountsService/users
    install -m 644 /tmp/owode-vm-payload/vm-state.js /usr/local/share/owode-ci/vm-state.js
    # Guest-only instrumentation, never included in the installed session package.
    cat >> /etc/environment <<'EOF'
QT_QUICK_BACKEND=software
LIBGL_ALWAYS_SOFTWARE=1
WAYLAND_DEBUG=client
QT_LOGGING_RULES=kwin_scripting.debug=true;js.debug=true
EOF
    cat > /var/lib/AccountsService/users/owodeci <<'EOF'
[User]
Session=owode
SessionType=wayland
SystemAccount=false
EOF
    chmod 600 /var/lib/AccountsService/users/owodeci
    cat > /etc/gdm/custom.conf <<'EOF'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=owodeci
WaylandEnable=true
[debug]
Enable=true
EOF
    restorecon -RF /var/lib/AccountsService/users /etc/gdm /usr/local/share/owode-ci
    systemctl restart accounts-daemon.service
    systemctl start gdm.service
    wait_owode
    # Select the actual GDM user session, never the parallel SSH session.
    session=
    for candidate in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
        if [[ $(loginctl show-session "$candidate" -p Name --value) == owodeci && \
              $(loginctl show-session "$candidate" -p Service --value) == gdm-autologin ]]; then
            session=$candidate; break
        fi
    done
    [[ -n $session ]]
    loginctl show-session "$session" > "$out/owode-session.txt"
    grep -Fx Type=wayland "$out/owode-session.txt"
    grep -Fx Class=user "$out/owode-session.txt"
    # GDM uses the session entry basename for logind's session identifier;
    # DesktopNames=owoDE is the separate XDG_CURRENT_DESKTOP brand/compat identity.
    grep -Fx Desktop=owode "$out/owode-session.txt"
    grep -Fx Active=yes "$out/owode-session.txt"
    printf '%s\n' "$session" > "$out/owode-session-id.txt"
    # Rootless user-owned compositor, no Plasma/GNOME shell in the owoDE account.
    pgrep -u "$uid" -x kwin_wayland > "$out/kwin-pids.txt"
    pgrep -u "$uid" -x klde-shell > "$out/shell-pids.txt"
    if pgrep -u "$uid" -x 'plasmashell|gnome-shell'; then exit 1; fi
    bus org.kde.KWin /KWin org.kde.KWin supportInformation > "$out/kwin-support.json"
    python3 - "$out/kwin-support.json" <<'PY'
import json, sys
support = json.load(open(sys.argv[1]))['data'][0]
assert 'DRM' in support or 'drm' in support, support
assert 'Operation Mode: Xwayland' in support or 'Operation Mode: Wayland' in support, support
PY
    # Observe roles with KWin independently of a screenshot or QML assumptions.
    script_id=$(bus org.kde.KWin /Scripting org.kde.kwin.Scripting loadScript ss \
        /usr/local/share/owode-ci/vm-state.js owode-cloud-vm-audit | python3 -c 'import json,sys;print(json.load(sys.stdin)["data"][0])')
    [[ $script_id =~ ^[0-9]+$ ]]
    bus org.kde.KWin "/Scripting/Script$script_id" org.kde.kwin.Script run
    # Obtain display environment from the real GDM-started shell, not SSH.
    pid=$(head -1 "$out/shell-pids.txt")
    mapfile -d '' environment < "/proc/$pid/environ"
    display_env=()
    for entry in "${environment[@]}"; do
        case $entry in WAYLAND_DISPLAY=*|DISPLAY=*|XDG_CURRENT_DESKTOP=*|XDG_SESSION_DESKTOP=*) display_env+=("$entry");; esac
    done
    as_user env "${display_env[@]}" GDK_BACKEND=wayland owode-run --gnome -- gnome-calculator > "$out/gnome-calculator.log" 2>&1 &
    as_user env "${display_env[@]}" QT_QPA_PLATFORM=wayland owode-run --kde -- kcalc > "$out/kcalc.log" 2>&1 &
    # Bounded acceptance polling is test code; the production shell remains event-driven.
    for _ in $(seq 1 45); do
        journalctl -b --no-pager -o cat > "$out/journal.log"
        if python3 - "$out" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
for line in reversed((root / 'journal.log').read_text(errors='replace').splitlines()):
    if 'OWODE_VM_STATE:' not in line: continue
    try: windows = json.loads(line.split('OWODE_VM_STATE:', 1)[1])
    except json.JSONDecodeError: continue
    apps = [w['appId'].lower() for w in windows if w['normal']]
    if (any('gnome.calculator' in a or 'gnome-calculator' in a for a in apps)
            and any('kcalc' in a for a in apps)
            and any(w['desktop'] and not w['normal'] for w in windows)
            and sum(bool(w['dock']) for w in windows) >= 2):
        (root / 'kwin-windows.json').write_text(json.dumps(windows, indent=2) + '\n')
        sys.exit(0)
sys.exit(1)
PY
        then break; fi
        sleep 2
    done
    test -s "$out/kwin-windows.json"
    python3 /tmp/owode-vm-payload/wait-native-buffers.py "$out/journal.log" "$out/first-buffers.json" \
        --roles wallpaper ribbon dock --timeout 5
    ;;
logout)
    # Disable ONLY the throwaway guest's autologin before ending the owned session.
    sed -i 's/^AutomaticLoginEnable=True$/AutomaticLoginEnable=False/' /etc/gdm/custom.conf
    bus org.owode.Session /org/owode/Session org.owode.Session1 logout > "$out/logout.json"
    python3 - "$out/logout.json" <<'PY'
import json, sys
assert json.load(open(sys.argv[1]))['data'] == [True]
PY
    original=$(cat "$out/owode-session-id.txt")
    for _ in $(seq 1 60); do
        if ! pgrep -u "$uid" -x kwin_wayland > /dev/null && \
           ! pgrep -u "$uid" -x klde-shell > /dev/null && \
           ! loginctl show-session "$original" > /dev/null 2>&1 && \
           pgrep -u gdm -x gnome-shell > /dev/null; then
            # Greeter must be an active Wayland greeter session, not just a process.
            for candidate in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
                if [[ $(loginctl show-session "$candidate" -p Class --value) == greeter && \
                      $(loginctl show-session "$candidate" -p Active --value) == yes ]]; then
                    loginctl show-session "$candidate" > "$out/returned-greeter.txt"
                    grep -Fx Type=wayland "$out/returned-greeter.txt"
                    exit 0
                fi
            done
        fi
        sleep 2
    done
    echo 'Owned session did not cleanly return to the active GDM greeter.' >&2; exit 1
    ;;
*) exit 2;;
esac
