// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import KLDE.Backends

Item {
    id: root
    clip: true
    required property var reading
    property string sizeMode: "standard"
    readonly property string phase: reading.phase
    readonly property bool rainy: phase === "rainy-evening"
    readonly property bool night: phase === "starry-night" || phase === "moonlit-night"
    readonly property bool activeMotion: visible && Shell.blur.renderingAllowed && !Tokens.reducedMotion
    property bool initialized: false
    Component.onCompleted: initialized = true
    onPhaseChanged: if (initialized && activeMotion)
        sceneTransition.restart()
    onActiveMotionChanged: if (initialized && !activeMotion) {
        sceneTransition.stop();
        opacity = 1;
    }
    NumberAnimation {
        id: sceneTransition
        target: root
        property: "opacity"
        from: 0.8
        to: 1
        duration: Tokens.motionNormal
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Tokens.temporalPalettes[root.phase][0]
            }
            GradientStop {
                position: 1
                color: Tokens.temporalPalettes[root.phase][1]
            }
        }
    }
    Rectangle {
        visible: root.reading.sunVisible
        width: parent.height * Tokens.temporalOrbRatio
        height: width
        radius: width / 2
        x: parent.width * root.reading.sunX - width / 2
        y: parent.height * root.reading.sunY - height / 2
        color: root.phase === "sunset" ? Tokens.temporalSunsetOrb : Tokens.temporalDayOrb
        Behavior on x {
            enabled: root.activeMotion
            NumberAnimation {
                duration: Tokens.motionNormal
            }
        }
        Behavior on y {
            enabled: root.activeMotion
            NumberAnimation {
                duration: Tokens.motionNormal
            }
        }
    }
    Image {
        visible: root.reading.moonVisible
        source: visible && root.visible ? "qrc:/assets/temporal/moon.svg" : ""
        width: parent.height * Tokens.temporalOrbRatio
        height: width
        x: parent.width * root.reading.moonX - width / 2
        y: parent.height * root.reading.moonY - height / 2
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
    }
    Image {
        anchors.fill: parent
        source: root.visible ? "qrc:/assets/temporal/" + root.phase + "-land-" + root.sizeMode + ".svg" : ""
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        cache: true
    }
}
