// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import KLDE.Backends

Item {
    id: root
    property real pixelSize: Tokens.ambientClockSize * Tokens.textScale
    readonly property var reading: Shell.time.reading
    implicitWidth: pixelSize * (Tokens.displayClockDigitWidth * 4 + Tokens.displayClockColonWidth)
    implicitHeight: pixelSize * Tokens.displayClockLineHeight
    Accessible.role: Accessible.StaticText
    Accessible.name: reading.timeText
    Row {
        anchors.centerIn: parent
        Repeater {
            model: [root.reading.hours[0], root.reading.hours[1], ":", root.reading.minutes[0], root.reading.minutes[1]]
            delegate: Item {
                id: digit
                required property string modelData
                width: root.pixelSize * (modelData === ":" ? Tokens.displayClockColonWidth : Tokens.displayClockDigitWidth)
                height: root.implicitHeight
                Label {
                    anchors.fill: parent
                    visible: digit.modelData !== ":"
                    text: digit.modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: Tokens.displayClockFont
                    font.weight: Tokens.displayClockWeight
                    font.pixelSize: root.pixelSize
                    font.letterSpacing: Tokens.displayClockTracking
                    color: Tokens.primary
                }
                Column {
                    visible: digit.modelData === ":"
                    anchors.centerIn: parent
                    spacing: root.pixelSize * Tokens.displayClockColonGap
                    Repeater {
                        model: 2
                        Rectangle {
                            width: root.pixelSize * Tokens.displayClockColonDot
                            height: width
                            radius: width / 2
                            color: Tokens.primary
                        }
                    }
                }
            }
        }
    }
}
