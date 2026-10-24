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
    scale: control.down ? Tokens.pressScale : control.hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.emphasized ? Tokens.textOnPrimary : Tokens.textPrimary
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
                duration: Tokens.springSpatialMicro.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springSpatialMicro.curve
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
        }
    }
}
