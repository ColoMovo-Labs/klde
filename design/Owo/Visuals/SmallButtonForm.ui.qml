// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string iconName: "settings"
    property bool selected: false
    property bool toggle: false
    property real shapeRadius: selected ? Tokens.radiusPill : Tokens.radiusM
    property color shapeColor: selected ? Tokens.primary : down ? Tokens.primaryContainer : hovered ? Tokens.surfaceContainerHigh : Tokens.surfaceContainer
    checkable: toggle
    checked: selected
    implicitWidth: Tokens.controlHeight
    implicitHeight: Tokens.controlHeight
    hoverEnabled: true
    Accessible.name: text
    ToolTip.visible: hovered
    ToolTip.text: text
    background: Rectangle {
        radius: root.shapeRadius
        color: root.shapeColor
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
