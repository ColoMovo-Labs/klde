// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property real shapeRadius: root.hovered || root.activeState ? Tokens.radiusL : Tokens.radiusM
    property color shapeColor: root.down ? Tokens.primaryContainer : root.hovered ? Tokens.surfaceContainer : "transparent"
    property string label: "Application"
    property string glyph: "folder"
    property bool runningState: false
    property bool activeState: false
    property int windowCount: runningState ? 1 : 0
    padding: 0
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
        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.space3
            Repeater {
                model: root.runningState ? Math.min(3, Math.max(1, root.windowCount)) : 0
                Rectangle {
                    width: Tokens.space4
                    height: Tokens.space4
                    radius: Tokens.radiusPill
                    color: Tokens.primary
                }
            }
        }
    }
}
