// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool emphasized: false
    implicitHeight: Tokens.controlHeight
    leftPadding: Tokens.space16
    rightPadding: Tokens.space16
    font: Tokens.label
    opacity: enabled ? 1 : Tokens.mutedOpacity
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.emphasized ? Tokens.onPrimary : Tokens.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: control.down ? Tokens.radiusM : Tokens.radiusPill
        color: control.emphasized ? Tokens.primary : control.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
        border.width: control.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
        Behavior on radius {
            NumberAnimation {
                duration: Tokens.motionFast
            }
        }
    }
}
