// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals

DockItemForm {
    Behavior on shapeRadius {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    Behavior on shapeColor {
        ColorAnimation {
            duration: Tokens.springEffectsFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springEffectsFast.curve
        }
    }

    scale: down ? Tokens.pressScale : hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    property string appId: ""
    property var actionTarget: null
    onClicked: if (actionTarget)
        actionTarget.activateApp(appId, -1)
}
