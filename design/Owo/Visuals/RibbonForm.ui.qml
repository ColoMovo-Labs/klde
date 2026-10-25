// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.previewWidth
    implicitHeight: Math.max(centerHeight, leftHost.y + leftHost.height, rightHost.y + rightHost.height)
    height: implicitHeight
    property bool stacked: width < Tokens.ribbonStackThreshold
    readonly property real sideWidth: stacked ? (width - Tokens.ribbonGroupGap) / 2 : centerHost.x - Tokens.ribbonGroupGap
    property real leftWidth: root.width >= Tokens.ribbonFoldThreshold ? 128 + 160 + 192 + Tokens.ribbonGroupGap * 2 : 128 + 160 + Tokens.ribbonGroupGap
    property real rightWidth: root.width >= Tokens.ribbonFoldThreshold ? 152 + 168 + 160 + Tokens.ribbonGroupGap * 2 : 168 + 160 + Tokens.ribbonGroupGap
    property real centerWidth: Tokens.temporalWidth
    property real centerHeight: Tokens.temporalHeight
    property alias leftHost: leftHost
    property alias centerHost: centerHost
    property alias rightHost: rightHost
    property bool showSamples: true
    Item {
        id: leftHost
        x: 0
        y: root.stacked ? Tokens.ribbonBandHeight + Tokens.ribbonGroupGap : 0
        width: Math.min(root.leftWidth, root.sideWidth)
        height: root.showSamples ? sampleLeft.implicitHeight : Tokens.ribbonBandHeight
        Flow {
            id: sampleLeft
            width: parent.width
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
    }

    Item {
        id: centerHost
        x: (parent.width - width) / 2
        y: (Tokens.ribbonBandHeight - height) / 2
        width: root.centerWidth
        height: root.centerHeight
        TemporalLandscapeForm {
            anchors.fill: parent
            visible: root.showSamples
        }
        TemporalTextForm {
            anchors.fill: parent
            visible: root.showSamples
        }
    }
    Item {
        id: rightHost
        x: parent.width - width
        y: leftHost.y
        width: Math.min(root.rightWidth, root.sideWidth)
        height: root.showSamples ? sampleRight.implicitHeight : Tokens.ribbonBandHeight
        Flow {
            id: sampleRight
            width: parent.width
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
}
