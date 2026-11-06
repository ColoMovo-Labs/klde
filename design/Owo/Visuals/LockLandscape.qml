// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Shared by the installed greeter and Visual Lab. No shell backend, network,
// credentials or authentication state belongs in this presentation component.
Item {
    id: root
    property url wallpaperSource
    property url foregroundSource
    property url clockFontSource
    property string timeText: ""
    property string dateText: ""
    property bool depthEnabled: true
    property bool transparencyEnabled: false
    property bool blurEnabled: true
    property int blurQuality: 2
    // Bounded translucency follows the shell's effect tier. Keep the digits
    // sharp instead of running a live blur in the authentication process.
    readonly property real clockOpacity: transparencyEnabled && blurEnabled ? [1, 0.94, 0.90, 0.86][Math.max(0, Math.min(3, blurQuality))] : 1
    property color clockColor: "#173b61"
    property color dateColor: "#15233c"
    readonly property bool depthActive: depthEnabled && background.status === Image.Ready && foreground.status === Image.Ready
    readonly property real clockPixelSize: Math.min(height * 0.36, width * 0.24, 400)
    clip: true

    FontLoader {
        id: clockFace
        source: root.clockFontSource
    }
    Image {
        id: background
        objectName: "lockLandscapeBackground"
        anchors.fill: parent
        source: root.wallpaperSource
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
    }
    Text {
        id: clock
        objectName: "lockAmbientClock"
        anchors.horizontalCenter: parent.horizontalCenter
        // Anchor the baseline, not the text box: only the feet of the right
        // digits meet the mountain summit, including on short/wide displays.
        y: root.height * 0.32 - baselineOffset
        text: root.timeText
        textFormat: Text.PlainText
        color: root.clockColor
        opacity: root.clockOpacity
        font.family: clockFace.status === FontLoader.Ready ? clockFace.name : "Sans Serif"
        font.pixelSize: root.clockPixelSize
        font.weight: Font.ExtraBold
        font.variableAxes: ({
                "wght": 800
            })
        font.features: ({
                "tnum": 1
            })
        Accessible.role: Accessible.StaticText
        Accessible.name: root.timeText
    }
    Image {
        id: foreground
        objectName: "lockMountainForeground"
        anchors.fill: parent
        source: root.depthEnabled ? root.foregroundSource : ""
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
        visible: root.depthActive
        // Same viewBox and crop as the background. Never scale this mask
        // independently: that produces a second, misaligned mountain ridge.
    }
    Text {
        id: date
        objectName: "lockLandscapeDate"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(clock.y + clock.height + 12, root.height * 0.37)
        width: Math.max(0, parent.width - 48)
        text: root.dateText
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: root.dateColor
        font.pixelSize: Math.min(24, Math.max(16, root.height * 0.025))
        font.weight: Font.Medium
    }
}
