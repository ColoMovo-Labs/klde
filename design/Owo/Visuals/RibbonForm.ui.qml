// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
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
        SurfaceForm {
            visible: root.showSamples && root.width >= Tokens.ribbonFoldThreshold
            width: 192
            height: Tokens.ribbonBandHeight
            cornerRadius: height / 2
            Row {
                anchors.centerIn: parent
                spacing: Tokens.space4
                Repeater {
                    model: ["1 F", "2", "3", "4", "5"]
                    delegate: Button {
                        required property string modelData
                        required property int index
                        width: index === 0 ? 56 : 24
                        height: 32
                        text: modelData
                        font: Tokens.label
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: index === 0 ? Tokens.textOnPrimary : Tokens.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: Tokens.radiusPill
                            color: index === 0 ? Tokens.primary : "transparent"
                        }
                    }
                }
            }
        }
    }

    Item {
        id: centerHost
        anchors.centerIn: parent
        width: Tokens.temporalWidth
        height: Tokens.temporalHeight
        TemporalLandscapeForm {
            anchors.fill: parent
            visible: root.showSamples
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
            visible: root.showSamples && root.width >= Tokens.ribbonFoldThreshold
            width: 152
            height: Tokens.ribbonBandHeight
            cornerRadius: height / 2
            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: Tokens.space2
                TelemetryCellForm {
                    iconName: "cpu"
                    valueText: "18%"
                }
                TelemetryCellForm {
                    iconName: "memory"
                    valueText: "57%"
                }
                TelemetryCellForm {
                    iconName: "thermometer"
                    valueText: "62°"
                }
                TelemetryCellForm {
                    iconName: "battery"
                    valueText: "74%"
                }
            }
        }
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
