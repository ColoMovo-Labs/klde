# Wayland first, X11 compatible

KLDE targets Wayland for its future default session and keeps X11/XCB as a
transitional compatibility path. It is neither Wayland-only nor X11-first.
The standalone preview uses Qt QPA and runs with `QT_QPA_PLATFORM=wayland` or
`QT_QPA_PLATFORM=xcb`. These are application paths, not installed KLDE sessions.

QML consumes capabilities, never Xlib/XCB calls or raw Wayland objects. Common
platform observations live in `src/platform/common`; concrete native adapters
will be added only with real consumers. DisplayServerBackend reports the QPA
path. WindowManagerBackend owns other-window/workspace requests; BlurBackend owns
effect capability. GlobalShortcutBackend, ScreenBackend, ClipboardBackend,
ScreenshotBackend and InputMethodBackend remain distinct responsibilities.
Reserved contracts do not imply those integrations are implemented.

Common behavior includes presentation, tokens, locale/voice, Qt input events,
application models and ordinary window lifecycle. Layer placement, exclusive
zones, global shortcuts, activation, secure locking, screen capture and native
backdrop effects require platform/portal/compositor cooperation. Do not use an
X11 geometry API as a substitute for a Wayland contract.

XWayland applications are acceptable compatibility clients in a Wayland session.
Test activation, scaling, clipboard, drag/drop, IME and mixed native/XWayland
workflows. Their presence must not make the shell itself depend on X11. An XCB
smoke under Xvfb proves neither XWayland integration nor an X11 login session.

A future display manager may offer KLDE (Wayland) and KLDE (X11), with Wayland
default. Legacy software, remote tools, specialist graphics and driver/input
issues justify compatibility testing. X11 support has no perpetual guarantee;
removal needs published evidence, migration options and a new decision review.

No compositor is chosen. KWin as an engine does not imply Plasma presentation;
wlroots and other existing engines remain candidates. A compositor fork requires
its own maintenance argument. Headless correctness is separate from GPU speed.
