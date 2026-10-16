# Input methods: Fcitx 5 first

Fcitx 5 is the KLDE 0.x default engine/compatibility infrastructure. KLDE owns its
indicator, settings and visual integration, not Pinyin parsing, dictionaries,
ranking, Rime or application input modules. IBus is a possible later adapter,
not a second framework maintained at bootstrap.

InputMethodBackend exposes availability, provenance, methods and requested state.
The initial Fcitx5Backend observes the session-bus service `org.fcitx.Fcitx5`
asynchronously and follows owner changes. Detection does not prove a working
input context, installed Pinyin or actual current method. The indicator's method
choice is explicitly a preview; real switching/control returns unsupported.
No daemon is started, user configuration written or host input selection changed.

Use Qt's normal TextField/TextArea input context. Fcitx setup depends on toolkit,
compositor and session; do not globally force one environment-variable recipe.
See [Fcitx setup](https://fcitx-im.org/wiki/Setup_Fcitx_5), its
[Wayland guidance](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland),
[public D-Bus reference](https://fcitx-im.org/wiki/DBus_Interface) and
[Qt service watching](https://doc.qt.io/qt-6/qdbusservicewatcher.html).
The upstream guides contain version-specific and historical advice; validate
against installed Qt/Fcitx and compositor versions before changing session setup.

The original KLDE light/dark Classic UI theme prototype belongs under
`assets/fcitx5/`. Its installation does not select it or restart Fcitx. Candidate
latency wins over decoration: no candidate animation loop or live blur. Theme
files are reviewed against the [official theme format](https://fcitx-im.org/wiki/Create_a_new_Fcitx_Theme).
Native candidate rendering and automatic Power Scene synchronization are deferred.

Future native surfaces must respect text-input-v3, input-method-v2, caret
rectangles, popup roles and compositor cooperation. A D-Bus engine connection
does not grant global coordinates. Do not scrape other applications or create a
compositor merely to position candidates. X11 flexibility must not define the UX.

## Manual acceptance matrix

For each native Wayland, XCB and mixed XWayland session record compositor, Fcitx,
Qt/GTK versions, input modules, scaling and installed engines. Test KLDE fields,
Qt 6, GTK 3/4, Firefox, Chromium, one Electron app, terminal, LibreOffice and a
JetBrains IDE when available. For each check preedit, candidate selection/caret
placement, method switching, punctuation, emoji, copy/paste and mixed Chinese/
English entry. Repeat at multiple scales/outputs, with Pinyin and optional Rime.
Record failures and latency; do not mark a row passed from a headless startup.

CI checks no-service fallback and mock selection, plus Wayland/XCB shell startup.
Interactive preedit/candidate acceptance and real Fcitx controls remain manual
future work; CI cannot replace them.
