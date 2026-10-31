// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property real shapeRadius: root.hovered || root.activeState ? Tokens.radiusL : Tokens.radiusM
    property color shapeColor: root.activeState || root.down ? Tokens.primaryContainer : root.hovered ? Tokens.surfaceContainer : "transparent"
    property string label: "Application"
    property string glyph: "folder"
    property bool runningState: false
    property bool activeState: false
    Accessible.name: root.label
    ToolTip {
        id: applicationToolTip
        visible: root.hovered
        text: root.label
        contentItem: Text {
            objectName: "applicationToolTipText"
            text: applicationToolTip.text
            textFormat: Text.PlainText
            font: applicationToolTip.font
            color: applicationToolTip.palette.toolTipText
        }
    }
    hoverEnabled: true
    background: Rectangle {
        radius: root.shapeRadius
        color: root.shapeColor
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
    contentItem: Item {
        Glyph {
            anchors.centerIn: parent
            width: Tokens.dockIcon
            height: Tokens.dockIcon
            name: root.glyph
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.activeState ? Tokens.space12 : Tokens.space4
            height: Tokens.space3
            radius: Tokens.radiusPill
            color: Tokens.primary
            visible: root.runningState
        }
    }
}
