// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Popup {
    padding: Tokens.space24
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle {
        radius: Tokens.radiusXL
        color: Tokens.surfaceElevated
        border.width: Tokens.space1
        border.color: Tokens.outline
    }
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Tokens.motionNormal
            }
            NumberAnimation {
                property: "scale"
                from: Tokens.popupStartScale
                to: 1
                duration: Tokens.motionNormal
                easing.type: Tokens.emphasizedDecelerate
            }
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Tokens.motionFast
        }
    }
}
