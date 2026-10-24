// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Popup {
    id: root
    property Item backdropSource: null
    padding: Tokens.space24
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onOpened: popupSurface.refreshCapture()
    background: Surface {
        id: popupSurface
        padding: 0
        backdropSource: root.backdropSource
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
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Tokens.motionFast
                easing.type: Tokens.emphasizedAccelerate
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
