// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls

Button {
    id: control
    property real shapeRadius: control.down ? Tokens.radiusM : Tokens.radiusPill
    property color shapeColor: control.emphasized ? Tokens.primary : control.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
    readonly property color stateInk: control.emphasized ? Tokens.textOnPrimary : Tokens.primary
    property bool emphasized: false
    implicitHeight: Tokens.controlHeight
    leftPadding: Tokens.space16
    rightPadding: Tokens.space16
    font: Tokens.label
    hoverEnabled: true
    opacity: enabled ? 1 : Tokens.mutedOpacity

    contentItem: Text {
        text: control.text
        textFormat: Text.PlainText
        font: control.font
        color: control.emphasized ? Tokens.textOnPrimary : Tokens.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: control.shapeRadius
        color: control.shapeColor
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: control.stateInk
            opacity: !control.enabled ? 0 : control.down ? 0.12 : control.hovered ? 0.08 : 0
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Tokens.space4
            radius: parent.radius + Tokens.space4
            color: "transparent"
            visible: control.visualFocus
            border.width: Tokens.space2
            border.color: Tokens.primary
        }
    }
}
