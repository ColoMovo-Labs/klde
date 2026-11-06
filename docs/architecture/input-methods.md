# Input methods: Fcitx 5 through KWin

The native/system path uses a real Fcitx 5 controller. The Visual Lab does not
start an input daemon or read the owner's controller; its two choices remain
fixed mock data. owoDE owns the indicator and integration, not dictionaries,
Pinyin ranking, Rime, application input modules or candidate engine code.

## Session startup and scope

`start-owode` gives KWin `--inputmethod /usr/libexec/owode-input-method`. This
per-process option scopes the default to owoDE without editing the user's shared
kwinrc, kdeglobals or GNOME settings. KWin supplies a privileged WAYLAND_SOCKET;
its packaged Fcitx Wayland launcher then reuses a running service or activates
one over D-Bus and transfers that socket. It does not kill or replace an existing
daemon. Running `fcitx5 -d --replace` after compositor startup is not equivalent:
it can lose KWin's privileged input-method connection.

The helper reads the distribution-owned fcitx5-wayland-launcher.desktop entry,
accepts its absolute executable with an optional --reopen argument, and checks
that the installed launcher supports --reopen. It never evaluates shell syntax
from a desktop entry. The managed-session marker and numeric WAYLAND_SOCKET are
required for actual execution; `--check` only inspects prerequisites.

The owoDE process tree sets XMODIFIERS=@im=fcitx for Xwayland and clears global
GTK_IM_MODULE, QT_IM_MODULE, QT_IM_MODULES and SDL_IM_MODULE overrides. Normal
Qt/GTK Wayland applications use text-input instead. The explicit activation
allowlist carries those values to session-activated applications. This is not a
change to shell startup files or another desktop's persistent configuration.
As with the display activation environment, concurrent graphical sessions for
one Unix user sharing a user bus need separate acceptance; do not claim isolation
from another active desktop's activation manager. Never run the login entry
inside a protected graphical host; nested tests use a private bus instead.

KWin 6.7 uses **input-method-v1**, with its supported text-input protocols on the
application side; this is not wlroots' input-method-v2. Native capability must be
verified against each compositor version. The initial supported controller ABI
is Fcitx 5.1.19+ (Ubuntu 26.04's published package); Fedora verification targets
5.1.23 + KWin 6.7.5. Ubuntu ABI/source inspection is not Ubuntu runtime acceptance.

Sources: [Fcitx Wayland guidance](https://www.fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland),
[KWin 6.7 startup](https://invent.kde.org/plasma/kwin/-/blob/Plasma/6.7/src/main_wayland.cpp),
[upstream launcher](https://github.com/fcitx/fcitx5/blob/5.1.19/src/tools/wayland-launcher.cpp),
[Ubuntu 26.04 package](https://packages.ubuntu.com/resolute/fcitx5).
No upstream implementation was copied into owoDE; the distribution's binaries
are used through their existing interfaces.

## State and control

The backend asynchronously follows org.fcitx.Fcitx5 ownership and calls the public
/controller interface org.fcitx.Fcitx.Controller1. FullInputMethodGroupInfo lists
only configured methods and their real labels; CurrentInputMethod reports the
active/last-relevant context; SetCurrentIM requests a change. UI state updates
from a subsequent query, not an optimistic mock edit. Only configured IDs can
be requested. Missing service, unsupported API or failed requests never turn
into a simulated Pinyin/English indicator in the live session.

The controller has no dedicated current-method change signal. Fcitx's
StatusNotifier item emits icon/tooltip changes for context/method changes; the
[tray host](status-notifier.md) forwards that event with its application ID.
Only Fcitx events refresh this backend. InputMethodGroupsChanged, opening the
input popup and a completed control request also refresh it. A finite 50 ms
coalescer bounds bursts; there is no idle polling. In-flight replies from an
old owner cannot overwrite a newly connected owner. A missing/disabled Fcitx
notification-item addon limits automatic shortcut tracking; opening the popup
still queries current state. The default supported configuration includes that
addon. No global key listener is installed merely to infer input state.

Configure Fcitx 5 delegates to the engine's Configure method when the matching
configuration executable is available. owoDE does not rewrite an existing
profile, force a Chinese timezone/region, or silently add engines to the user's
list. Fedora recommends fcitx5-chinese-addons and fcitx5-configtool; installations
using --setopt=install_weak_deps=False must add them explicitly if needed.

Protocol references: [public controller](https://fcitx-im.org/wiki/DBus_Interface),
[5.1.19 controller ABI](https://github.com/fcitx/fcitx5/blob/5.1.19/src/modules/dbus/dbusmodule.cpp),
[notification-item events](https://github.com/fcitx/fcitx5/blob/5.1.19/src/modules/notificationitem/notificationitem.cpp).
No input text is logged by the production backend. Native tests save only their
synthetic preedit and the fixed verification phrase.

## Fedora 44 真机验收

1. 安装同一提交的两个 RPM，保存工作后退出并重新选择 owoDE 登录。
   `start-owode --check` 应显示 KWin 和 Fcitx 启动入口可用。
2. 点击顶栏输入法指示器：列表来自当前 Fcitx 配置；不能把“已连接”当成所有应用
   已兼容。若没有拼音，打开“设置 → 语言与输入 → 配置 Fcitx 5”，添加“拼音”。
   若缺少引擎或配置工具，安装 `fcitx5-chinese-addons fcitx5-configtool`。
3. 在终端、owoDE 搜索框、Qt 6 应用和 GTK 应用分别输入 `nihao`，检查预编辑、
   候选位置、空格提交、中文标点和中英切换。快捷键切换后，顶栏应随真实输入法更新。
4. 分别检查单屏/双屏、100%/150% 缩放、Firefox、Chromium/Electron、LibreOffice、
   JetBrains 和 Xwayland 应用。旧 X11 应用可能需要单独安装/指定匹配的输入模块；
   不要为修一个应用给整个 Wayland 会话强制 GTK_IM_MODULE/QT_IM_MODULE。
5. 原有 GNOME 会话仍应使用其原本配置。不要从托盘重启 KWin 管理的 Fcitx，重启
   可能丢掉专用 socket；保存工作后退出并重新登录 owoDE 来重建它。

若登录失败，从登录管理器选择原来的 GNOME/niri；或 Ctrl+Alt+F3 登录 TTY 查看
`journalctl --user -b`、`start-owode --check` 和包版本。必要时用上一套匹配的两个
RPM 回退。不要终止整个用户或替换宿主合成器。若是锁屏无法解锁，先用
`loginctl list-sessions` 找自己的图形会话，再 `loginctl unlock-session <ID>`。
不要公开密码或含私密输入内容的日志。

## Cloud evidence and limits

- Private D-Bus fixture tests cover ownership, real method signatures, native
  labels, asynchronous switching, failures, group updates and service loss.
- `OWODE_CLOUD_FCITX_TEST=1 bash tools/fcitx-native-smoke.sh build/fedora artifacts/fcitx-native`
  starts isolated Xvfb + D-Bus + KWin and **the same input-method helper**. A real
  Qt Wayland line edit receives Pinyin preedit and commits 你好. A physical
  Ctrl+Space sent to the private Xvfb viewport must update the backend without
  an explicit refresh. Screenshots show candidates, committed text and the tray;
  logs must contain input-method-v1 and application text-input traffic.
  KWin 6.7's X11 nested keyboard has an empty device name; its default empty
  KWIN_DEVICE_SKIPS_INPUT_METHOD value splits to an empty-name skip entry. The
  observed result was raw Latin keys bypassing an otherwise active input-method
  grab. This runner alone sets a nonmatching sentinel for that list. The
  production DRM login entry does not set it. See
  [the input filter](https://invent.kde.org/plasma/kwin/-/blob/Plasma/6.7/src/input.cpp)
  and [X11 device initialization](https://invent.kde.org/plasma/kwin/-/blob/Plasma/6.7/src/backends/x11/x11_windowed_backend.cpp).
  The test also lets Qt process events during injection and waits for the
  upstream launcher's initial socket handover; a controller query alone is
  not input-context readiness.
- The runner's two-method profile lives only in its private temporary directory;
  it is not installed as the user's preference. Software rendering establishes
  correctness, not GPU latency or hardware acceptance. The cloud test does not
  establish compatibility of every Qt/GTK/Electron application.

The original optional Classic UI themes under assets/fcitx5 remain available;
installation alone does not select them. Candidate latency takes precedence over
animation or live blur. See the [official theme format](https://fcitx-im.org/wiki/Create_a_new_Fcitx_Theme).
