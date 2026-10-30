# Production acceptance gates

The target is a production-capable desktop on Fedora 44, with Ubuntu 26.04
remaining the primary supported distribution. A package, screenshot, successful
build or registered login entry is not a production-readiness claim.

| Gate | Current boundary | Required acceptance |
| --- | --- | --- |
| Login/session lifecycle | Opt-in Fedora session package under development | Real GDM/SDDM login, DRM output, repeat logout/login, crash return to greeter |
| Native shell roles | LayerShellQt roles and isolated KWin tests exist | Fedora and Ubuntu protocol/input tests and owner hardware acceptance |
| Applications | Real XDG catalog, KIO launch, persistent pins | Wayland/Xwayland, activation, multiple instances, failed starts, app updates |
| GNOME/KDE applications | Compatibility work in progress | Actual GNOME GTK/libadwaita and KDE Qt applications with correct dependencies and portals |
| Window/workspace state | Mock workspace state remains | Real KWin state, activate/close, running indicators, workspace changes and shortcuts |
| Clock/date | Native mode uses local system time; mock previews remain deterministic | Timezone/time changes, DST and suspend/resume acceptance |
| Audio/network/power | Quick Settings still largely mock | Event-driven real services, disconnection/errors, permission handling, truthful disabled states |
| Notifications/tray | Preview components | Real notification server, actions, DND, StatusNotifier and app integration |
| Security/session lock | Lock-screen artwork is a preview | Compositor-enforced authenticated lock, suspend/resume, polkit and credential boundaries |
| Portals/input | Partial Fcitx integration | File chooser, open URI, screenshot/screencast consent, IME and clipboard behavior |
| Hardware | Cloud software-rendered correctness | Intel GPU and target hardware, multi-output/hotplug/scaling, idle power and frame times |
| Reliability/recovery | Cloud checks and rollback instructions | Soak tests, shell/compositor crash handling, update/rollback, package removal |

Do not ship mocked indicators as live system state or call the lock preview a
secure screen locker. Preserve Visual Lab as an explicit mock mode. Production
release requires closing these gates with recorded source/package versions and
reproducible results, including tests outside a software-rendered container.
