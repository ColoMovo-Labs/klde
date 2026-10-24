// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls

Popup {
    id: root
    property Item backdropSource: null
    padding: Tokens.space24
    focus: true
    transformOrigin: Item.Center
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onOpened: popupSurface.refreshCapture()
    background: Surface {
        id: popupSurface
        padding: 0
        material: "acrylic"
        backdropSource: root.backdropSource
    }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Tokens.springEffects.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffects.curve
            }
            NumberAnimation {
                property: "scale"
                from: Tokens.popupStartScale
                to: 1
                duration: Tokens.springPopup.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springPopup.curve
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: Tokens.popupStartScale
                duration: Tokens.motionFast
                easing.type: Tokens.emphasizedAccelerate
            }
        }
    }
}
