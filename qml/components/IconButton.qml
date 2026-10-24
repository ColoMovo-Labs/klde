// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Button {
    id: root
    property string iconName: "settings"
    property bool emphasized: false
    implicitWidth: Tokens.controlHeight
    implicitHeight: Tokens.controlHeight
    scale: root.down ? Tokens.pressScale : root.hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    Accessible.name: text
    ToolTip.visible: hovered && text.length > 0
    ToolTip.text: text
    contentItem: Icon {
        name: root.iconName
        lightInk: root.emphasized ? !Tokens.darkMode : Tokens.darkMode
        width: Tokens.iconM
        height: Tokens.iconM
    }
    background: Rectangle {
        radius: root.emphasized ? Tokens.radiusPill : Tokens.radiusM
        color: root.emphasized ? Tokens.primary : root.down ? Tokens.primaryContainer : root.hovered ? Tokens.surfaceContainer : "transparent"
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
        Behavior on color {
            ColorAnimation {
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
        }
    }
}
