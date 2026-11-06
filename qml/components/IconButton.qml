// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls

Button {
    id: root
    property string iconName: "settings"
    property bool emphasized: false
    implicitWidth: Tokens.controlHeight
    implicitHeight: Tokens.controlHeight
    hoverEnabled: true
    opacity: enabled ? 1 : Tokens.mutedOpacity
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
        radius: root.down ? Tokens.radiusM : root.emphasized ? Tokens.radiusPill : Tokens.radiusL
        color: root.emphasized ? Tokens.primary : root.down ? Tokens.primaryContainer : root.hovered ? Tokens.surfaceContainer : "transparent"
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.emphasized ? Tokens.textOnPrimary : Tokens.primary
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
        Behavior on color {
            ColorAnimation {
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
        }
    }
}
