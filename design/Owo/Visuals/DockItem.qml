// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

DockItemForm {
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
