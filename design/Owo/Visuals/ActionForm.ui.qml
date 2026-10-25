// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Button {
    id: control
    property real shapeRadius: control.down ? Tokens.radiusM : Tokens.radiusPill
    property color shapeColor: control.emphasized ? Tokens.primary : control.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
    property bool emphasized: false
    implicitHeight: Tokens.controlHeight
    leftPadding: Tokens.space16
    rightPadding: Tokens.space16
    font: Tokens.label
    opacity: enabled ? 1 : Tokens.mutedOpacity

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.emphasized ? Tokens.textOnPrimary : Tokens.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: control.shapeRadius
        color: control.shapeColor
        border.width: control.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
}
