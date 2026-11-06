// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string iconName: "settings"
    property bool selected: false
    property int iconSize: root.iconName === "klde" ? Tokens.iconL : Tokens.iconM
    property bool toggle: false
    property real shapeRadius: down ? Tokens.radiusM : selected ? Tokens.radiusPill : Tokens.radiusL
    property color shapeColor: selected ? Tokens.primary : down ? Tokens.primaryContainer : hovered ? Tokens.surfaceContainerHigh : Tokens.surfaceContainer
    checkable: toggle
    checked: selected
    implicitWidth: Tokens.controlHeight
    implicitHeight: Tokens.controlHeight
    hoverEnabled: true
    opacity: enabled ? 1 : Tokens.mutedOpacity
    Accessible.name: text
    ToolTip.visible: hovered
    ToolTip.text: text
    background: Rectangle {
        radius: root.shapeRadius
        color: root.shapeColor
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.selected ? Tokens.textOnPrimary : Tokens.primary
            opacity: !root.enabled ? 0 : root.down ? 0.12 : root.hovered ? 0.08 : 0
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Tokens.space4
            radius: parent.radius + Tokens.space4
            color: "transparent"
            visible: root.visualFocus
            border.width: Tokens.space2
            border.color: Tokens.primary
        }
    }
    contentItem: Item {
        Glyph {
            anchors.centerIn: parent
            name: root.iconName
            width: root.iconSize
            height: width
            lightInk: root.selected ? !Tokens.darkMode : Tokens.darkMode
        }
    }
}
