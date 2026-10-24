// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.previewWidth
    height: Tokens.ribbonBandHeight + Tokens.space16
    property alias leftHost: leftHost
    property alias centerHost: centerHost
    property alias rightHost: rightHost
    property bool showSamples: true
    Row {
        id: leftHost
        anchors.left: parent.left
        anchors.leftMargin: Tokens.space16
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.ribbonGroupGap
        SurfaceForm {
            visible: root.showSamples
            width: 128
            height: Tokens.ribbonBandHeight
            cornerRadius: height / 2
            Row {
                anchors.centerIn: parent
                spacing: Tokens.space12
                Glyph {
                    name: "klde"
                }
                Text {
                    text: "桌面"
                    font: Tokens.label
                    color: Tokens.textPrimary
                }
            }
        }
        SurfaceForm {
            visible: root.showSamples
            width: 160
            height: Tokens.ribbonBandHeight
            cornerRadius: height / 2
            Text {
                anchors.centerIn: parent
                text: "10月17日 周六"
                font: Tokens.label
                color: Tokens.textPrimary
            }
        }
    }
    Item {
        id: centerHost
        anchors.centerIn: parent
        width: Tokens.temporalWidth
        height: Tokens.temporalHeight
        SurfaceForm {
            anchors.fill: parent
            visible: root.showSamples
            cornerRadius: height / 2
            tone: "#91c8df"
        }
        TemporalTextForm {
            anchors.fill: parent
            visible: root.showSamples
        }
    }
    Row {
        id: rightHost
        anchors.right: parent.right
        anchors.rightMargin: Tokens.space16
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.ribbonGroupGap
        SurfaceForm {
            visible: root.showSamples
            width: 168
            height: Tokens.ribbonBandHeight
            cornerRadius: height / 2
            Row {
                anchors.centerIn: parent
                spacing: Tokens.space16
                Glyph {
                    name: "wifi"
                }
                Glyph {
                    name: "bluetooth"
                }
                Glyph {
                    name: "volume"
                }
            }
        }
        SurfaceForm {
            visible: root.showSamples
            width: 160
            height: Tokens.ribbonBandHeight
            cornerRadius: height / 2
            Row {
                anchors.centerIn: parent
                spacing: Tokens.space16
                Glyph {
                    name: "bell"
                }
                Glyph {
                    name: "settings"
                }
                Glyph {
                    name: "power"
                }
            }
        }
    }
}
