# LingmoOS / Cutefish component audit

Inspected 17 October 2026 through GitHub API: exact commit, root LICENSE/COPYING,
CMakeLists and the entry point/UI/service files listed in
[the reproducible inspection index](inspected-components.json). This is a bounded
source review, not a compilation, runtime security audit or proof of maintenance.
No source or artwork from these repositories is imported by this change.
Community permission context does not replace each file's license.

| Repository / pinned source | Actual finding and decision |
| --- | --- |
| [LingmoOS/LingmoUI @ 87ed8ecd4359](https://github.com/LingmoOS/LingmoUI/tree/87ed8ecd4359b236be687f97aafd7a242c5b6ba9) | Reference surfaces; avoid wholesale runtime dependency: GuiPrivate and X11 blur helper. |
| [LingmoOS/album @ a3af12a290f5](https://github.com/LingmoOS/album/tree/a3af12a290f5e919c9fddda851bbf61db2b22d10) | Evaluate separately: Qt6 but Deepin/DTK application and service names, substantial dependencies; not a tiny generic viewer. |
| [LingmoOS/lingmo-calculator @ 7e11870128d8](https://github.com/LingmoOS/lingmo-calculator/tree/7e11870128d8b2270878c507c70dd58862707fc3) | Promising external app candidate: Qt6/LingmoUI3; validate accessibility and translation separately. |
| [LingmoOS/lingmo-core @ 50f42d6c6531](https://github.com/LingmoOS/lingmo-core/tree/50f42d6c6531ce34852446278f27be8238a3a8f4) | Reference freedesktop notification server/history; Qt6, mixed file licenses and privileged/session helpers require isolation. |
| [LingmoOS/lingmo-daemon @ 610162449954](https://github.com/LingmoOS/lingmo-daemon/tree/610162449954c5ac12eca33493f7c9fe211cb5c0) | Avoid shell dependency: Qt5/QApt makes package management distribution-specific. |
| [LingmoOS/lingmo-dock @ 4f0f30a06515](https://github.com/LingmoOS/lingmo-dock/tree/4f0f30a06515bb45c011eca8c98c278e497ffe0f) | Reference app/task model; Qt6 GuiPrivate/KF6 and Lingmo service assumptions. |
| [LingmoOS/lingmo-filemanager @ c0ec387386c1](https://github.com/LingmoOS/lingmo-filemanager/tree/c0ec387386c174db9bb5461071dcb76fd91d3808) | Evaluate standalone app: Qt6/KF6 KIO/Solid/Config, LingmoUI3 and desktop/dock coupling to isolate. |
| [LingmoOS/lingmo-launcher @ eac296ecccf4](https://github.com/LingmoOS/lingmo-launcher/tree/eac296ecccf47c9d25eb989e06a7cc6e953129fb) | Reference app catalog/keyboard patterns; Qt6/KF6 and Lingmo service assumptions. |
| [LingmoOS/lingmo-qt-plugins @ 3a54d1a70b04](https://github.com/LingmoOS/lingmo-qt-plugins/tree/3a54d1a70b0434b609fce85ba11caa3dc8704e22) | Avoid global installation now. Platform theme/widget styles have separate build dependencies and mixed headers. |
| [LingmoOS/lingmo-screenlocker @ d16aa1d2b2cb](https://github.com/LingmoOS/lingmo-screenlocker/tree/d16aa1d2b2cb39489da4f2bbda06422cac09ec16) | Do not embed or imitate authentication. Qt5/X11; selected lock QML has GPL-3.0 marker, not an or-later grant. |
| [LingmoOS/lingmo-screenshots @ 12430cb7801b](https://github.com/LingmoOS/lingmo-screenshots/tree/12430cb7801b932294fb86fe4288dc70fbdebeaf) | Reference capture selection UX; Qt5/GraphicalEffects and service coupling. Wayland needs portal/compositor path. |
| [LingmoOS/lingmo-settings @ 78c6f1483594](https://github.com/LingmoOS/lingmo-settings/tree/78c6f1483594285dc01ea59591f761a570ecea80) | Reference selected service adapters; Qt6/KF6 plus X11 and Lingmo D-Bus names prevent direct replacement. |
| [LingmoOS/lingmo-statusbar @ ee5d766075b1](https://github.com/LingmoOS/lingmo-statusbar/tree/ee5d766075b145fd46fdcdebd87121208251a8ae) | Reference tray/menu/notification APIs; Qt/KF and private distro services are not a drop-in ribbon. |
| [LingmoOS/lingmo-terminal @ 276b3a46dab0](https://github.com/LingmoOS/lingmo-terminal/tree/276b3a46dab02cd48b530d9875e0bc604c0a55d4) | Reference/evaluate external app; Qt5 and bundled qmltermwidget require Qt6 port and file-level license inventory. |
| [LingmoOS/lingmo-texteditor @ 419fc5b8fb5e](https://github.com/LingmoOS/lingmo-texteditor/tree/419fc5b8fb5e4519fda1ea5e9b8581d876a1e918) | Evaluate external app; Qt5/KF5 SyntaxHighlighting and LingmoUI require port/packaging work. |
| [LingmoOS/lingmo-videoplayer @ 13f8946b630f](https://github.com/LingmoOS/lingmo-videoplayer/tree/13f8946b630f9bb42bb34809dc45c090a78a730b) | Evaluate external app: Qt5/libmpv, screensaver D-Bus and inherited player code; retain all authors. |
| [cutefishos/core @ 1dc644326c18](https://github.com/cutefishos/core/tree/1dc644326c18b9495b5a707a1075d15538eb328b) | Reference session supervision/service separation; Qt6, compositor launch scripts and privileged helpers are not shell UI. |
| [cutefishos/dock @ 0535d7c0bdc0](https://github.com/cutefishos/dock/tree/0535d7c0bdc0dfbd100301effe74034933b060b9) | Reference task model; Qt6/KF6 plus XCB; do not bind KLDE to its window API. |
| [cutefishos/filemanager @ 59fa83a5e62c](https://github.com/cutefishos/filemanager/tree/59fa83a5e62ce1d6d86d0a4e64c671f958039534) | Evaluate standalone app: Qt6/KF6, FishUI and separate desktop integration; no immediate fork. |
| [cutefishos/fishui @ 77e84001da0b](https://github.com/cutefishos/fishui/tree/77e84001da0b9a8d29797b0c8b850532c771c9da) | Reference public Wayland blur cooperation; Qt6 GuiPrivate/KF6/KWayland make wholesale adoption costly. |
| [cutefishos/kwin-plugins @ 5df71a4e6846](https://github.com/cutefishos/kwin-plugins/tree/5df71a4e684682e33b5630b7831206d504158937) | Do not install: writes KWin defaults/global shortcuts and assumes KWin; study only behind future backend. |
| [cutefishos/launcher @ 723e2f9f994e](https://github.com/cutefishos/launcher/tree/723e2f9f994e7cb83a008d3889eefeb330103f5d) | Reference app catalog/keyboard patterns; Qt6/KF6 and Cutefish service assumptions. |
| [cutefishos/qt-plugins @ bf650f604700](https://github.com/cutefishos/qt-plugins/tree/bf650f604700ae3ee8297328984c6dbaa9b95598) | Avoid global installation now. Platform theme/widget style/image plugins need per-file and Qt ABI review. |
| [cutefishos/screenlocker @ b852033bab79](https://github.com/cutefishos/screenlocker/tree/b852033bab79749dd5e9b0e4ef5e3f01bd1f7769) | Security-sensitive external research only. Qt6 with X11 discovery; a mock popup cannot provide secure locking. |
| [cutefishos/screenshot @ 2b5ce06de6f7](https://github.com/cutefishos/screenshot/tree/2b5ce06de6f78a161d4d389e1b2775f2ec09464a) | Reference capture UX; Qt5/GraphicalEffects. Do not use arbitrary screen capture assumptions on Wayland. |
| [cutefishos/settings @ de043226530b](https://github.com/cutefishos/settings/tree/de043226530b6ce2ca0121022295f83d8938163b) | Reference service adapters; Qt6/KF6 and Cutefish D-Bus contracts need adaptation. |
| [cutefishos/statusbar @ e4b9a614c342](https://github.com/cutefishos/statusbar/tree/e4b9a614c3420c9d25e03f25c077ea9fde3502b7) | Reference StatusNotifier/dbusmenu contracts; Qt6/KF6 and Cutefish services, inherited libraries need separate licenses. |
| [cutefishos/terminal @ cf5ab4cb24b6](https://github.com/cutefishos/terminal/tree/cf5ab4cb24b60d329e9664a5339e8011209c4a29) | Evaluate Qt6 app; CutefishFramework and inherited qmltermwidget remain dependencies. |

## License and integration findings

Root licenses inspected in these repositories carry GPL v3 text; that alone does
not establish an or-later grant for every file. Most application entry points
inspected explicitly allow v3 or later. Concrete exceptions matter:

- Lingmo Terminal and Cutefish Terminal vendor qmltermwidget Session files with
  GPL v2-or-later headers; preserve original Konsole/qterm authors and inspect the
  complete subproject before reuse.
- Lingmo Core notification QML offers GPL-2.0-only OR GPL-3.0-only OR a KDE accepted
  license reference. A GPL3 choice is available for that file, not a blanket
  conversion of the component.
- Lingmo screen lock QML uses an ambiguous historical GPL-3.0 SPDX marker. Resolve
  exact grants and all dependencies before deriving or combining code.
- Lingmo Qt widget-style blur helper has MIT-style notices from several authors;
  a root GPL badge does not replace those notices.
- Cutefish KWin tabbox QML is GPL-2.0-or-later and is specific to KWin's QML API.
- Lingmo Album entry/UI files name UnionTech and GPL-3.0-or-later; Deepin/DTK
  provenance and service names must remain visible in any adoption.

Several current Cutefish repositories now use Qt6/KF6. Calling the entire
ecosystem Qt5-only would be incorrect. Older screenshot and Lingmo terminal/editor
components still use Qt5. Source compatibility must be decided per pinned version.
FishUI's Wayland blur manager wraps compositor-provided blur, while LingmoUI's
compatible X11 helper includes private Qt X11 headers. Neither is justification
for KLDE to use private Qt APIs in the core.

## Default app evaluation

The conceptual app-suite panel lists ten categories, not installed defaults.
Files: compare Lingmo/Cutefish file managers with Peony; separate file browsing
from their desktop/dock services. Terminal: compare an independently packaged
Qt6 terminal such as QTerminal with the audited terminal ports. Settings stays
KLDE presentation over explicit services, with audited adapters as candidates.
Image viewer: Album is a substantial DTK dependency; compare a smaller viewer
before choosing it. Text editor, calculator and media player can stay standalone
processes. Screenshot must use a supported portal/compositor interface. Archive
and software-center candidates remain distribution tools pending their own
license/build audit; no claim of inspection of those unlisted sources is made.

Prefer external packaged applications over copying implementations. Any selected
source adaptation needs a narrow patch, full copyright/license inventory, port
plan, asynchronous service contract and CI coverage. Never install the audited
KWin defaults, replace the host's notification daemon, enable a lock service or
change Qt platform theme during this Visual Lab.
