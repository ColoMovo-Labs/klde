// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Item {
    id: root
    clip: true
    property var reading: ({
            phase: "cloudy-day",
            sunVisible: true,
            sunX: 0.2,
            sunY: 0.35,
            moonVisible: false,
            moonX: 0.8,
            moonY: 0.35
        })
    property string sizeMode: "standard"
    readonly property string phase: reading.phase
    property real sunX: reading.sunX
    property real sunY: reading.sunY
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
        x: parent.width * root.sunX - width / 2
        y: parent.height * root.sunY - height / 2
        color: root.phase === "sunset" ? Tokens.temporalSunsetOrb : Tokens.temporalDayOrb
    }
    Image {
        visible: root.reading.moonVisible
        source: visible && root.visible ? Assets.root + "temporal/moon.svg" : ""
        width: parent.height * Tokens.temporalOrbRatio
        height: width
        x: parent.width * root.reading.moonX - width / 2
        y: parent.height * root.reading.moonY - height / 2
        sourceSize: Qt.size(width * 1, height * 1)
    }
    Image {
        anchors.fill: parent
        source: root.visible ? Assets.root + "temporal/" + root.phase + "-land-" + root.sizeMode + ".svg" : ""
        sourceSize: Qt.size(width * 1, height * 1)
        cache: true
    }
}
