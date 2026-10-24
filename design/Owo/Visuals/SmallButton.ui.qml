// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string iconName: "settings"
    property bool selected: false
    implicitWidth: Tokens.controlHeight
    implicitHeight: Tokens.controlHeight
    hoverEnabled: true
    Accessible.name: text
    ToolTip.visible: hovered
    ToolTip.text: text
    background: Rectangle {
        radius: root.selected ? Tokens.radiusPill : Tokens.radiusM
        color: root.selected ? Tokens.primary : root.down ? Tokens.primaryContainer : root.hovered ? Tokens.surfaceContainerHigh : Tokens.surfaceContainer
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
    contentItem: Item {
        Glyph {
            anchors.centerIn: parent
            name: root.iconName
            lightInk: root.selected ? !Tokens.darkMode : Tokens.darkMode
        }
    }
}
