// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import KLDE.Backends

// The dock at its resting position plus the hide/reveal policy. The item's own
// geometry never moves, so layout anchored to it stays put; only the inner dock
// slides. While hidden, the input region is a thin strip on the screen edge.
Item {
    id: root
    // "smart", "reserve" or "hidden" (Shell.settings dock.mode).
    property string mode: "smart"
    // Distance from this item's bottom to the screen edge.
    property real edgeGap: Tokens.space24
    // Compositor-global position of this item's window; used for the overlap
    // test against KWin window geometry. Disabled in the preview window.
    property bool overlapEnabled: false
    property point globalOrigin: Qt.point(0, 0)
    property bool peeking: false
    // Widest the dock may grow, normally the screen width minus margins.
    property real maximumWidth: Tokens.previewWidth
    readonly property alias dock: dock
    property alias backdropSource: dock.backdropSource
    readonly property bool covered: {
        if (!overlapEnabled || mode !== "smart")
            return false;
        const windows = Shell.windowManager.windows;
        const workspace = Shell.windowManager.activeWorkspace;
        return windows.length > 0 && workspace.length > 0 && Shell.windowManager.windowOverlaps(Qt.rect(globalOrigin.x + x + dock.x, globalOrigin.y + y, dock.width, height));
    }
    readonly property bool hovered: dockHover.hovered || edgeHover.hovered
    readonly property bool wanted: mode === "reserve" || (mode === "smart" && !covered) || hovered || peeking
    property bool shown: wanted
    // 0 hidden … 1 shown. A finite spring; nothing animates once it settles.
    property real reveal: shown ? 1 : 0
    signal launcherRequested
    signal settingsRequested
    function focusLauncher(): void {
        peek();
        dock.focusLauncher();
    }
    // Briefly reveal a hidden dock, e.g. when Super is pressed.
    function peek(): void {
        peeking = true;
        peekTimer.restart();
    }
    implicitWidth: dock.width
    implicitHeight: dock.height
    onWantedChanged: {
        if (wanted) {
            hideTimer.stop();
            shown = true;
        } else {
            hideTimer.restart();
        }
    }
    Behavior on reveal {
        NumberAnimation {
            duration: root.shown ? Tokens.springSpatial.duration : Tokens.springEffects.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown ? Tokens.springSpatial.curve : Tokens.springEffects.curve
        }
    }
    Timer {
        id: hideTimer
        interval: 450
        onTriggered: root.shown = root.wanted
    }
    Timer {
        id: peekTimer
        interval: 1600
        onTriggered: root.peeking = false
    }
    Dock {
        id: dock
        objectName: "dock"
        width: Math.min(implicitWidth, root.maximumWidth)
        anchors.horizontalCenter: parent.horizontalCenter
        y: (1 - root.reveal) * (root.height + root.edgeGap + Tokens.space8)
        visible: root.reveal > 0
        opacity: Math.min(1, root.reveal * 2)
        onLauncherRequested: root.launcherRequested()
        onSettingsRequested: root.settingsRequested()
        HoverHandler {
            id: dockHover
        }
    }
    // The edge trigger: a thin strip while hidden, and while revealed by the
    // pointer a bridge from the screen edge up to the dock.
    Item {
        objectName: "dockEdgeTrigger"
        readonly property bool nativeInputSurface: true
        readonly property real cornerRadius: 0
        visible: root.mode !== "reserve" && (root.covered || root.mode === "hidden" || root.hovered)
        width: dock.width
        height: root.shown && root.hovered ? root.edgeGap : Tokens.space4
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height + root.edgeGap - height
        HoverHandler {
            id: edgeHover
        }
    }
}
