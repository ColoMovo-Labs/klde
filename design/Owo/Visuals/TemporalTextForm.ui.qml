// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property alias timeText: timeLabel.text
    property alias phaseText: phaseLabel.text
    property bool expanded: false
    property bool showTime: true
    property int inset: Tokens.temporalInset
    property int timePixelSize: Tokens.temporalFont
    property alias textColumn: textColumn
    property alias timeLabel: timeLabel
    property alias phaseLabel: phaseLabel
    Column {
        id: textColumn
        objectName: "temporalTextColumn"
        anchors.centerIn: parent
        width: parent.width - root.inset * 2
        spacing: Tokens.space4
        Text {
            id: timeLabel
            objectName: "temporalTimeText"
            visible: root.showTime
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "08:30"
            color: Tokens.temporalText
            font.family: Tokens.displayClockFont
            font.weight: Tokens.displayClockWeight
            font.pixelSize: root.timePixelSize * Tokens.textScale
        }
        Text {
            id: phaseLabel
            objectName: "temporalPhaseText"
            visible: root.expanded
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "晴朗午后"
            color: Tokens.temporalText
            font: Tokens.caption
        }
    }
}
