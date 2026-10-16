// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Button {
    id: root
    property string iconName: "settings"
    property bool emphasized: false
    implicitWidth: Tokens.controlHeight
    implicitHeight: Tokens.controlHeight
    Accessible.name: text
    ToolTip.visible: hovered && text.length > 0
    ToolTip.text: text
    contentItem: Icon {
        name: root.iconName
        width: Tokens.iconM
        height: Tokens.iconM
    }
    background: Rectangle {
        radius: root.emphasized ? Tokens.radiusL : Tokens.radiusM
        color: root.down || root.emphasized ? Tokens.primaryContainer : root.hovered ? Tokens.surfaceContainer : "transparent"
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
        Behavior on color {
            ColorAnimation {
                duration: Tokens.motionFast
            }
        }
    }
}
