// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

ActionForm {
    scale: down ? Tokens.pressScale : hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
}
