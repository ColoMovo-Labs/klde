// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    implicitHeight: Tokens.controlHeight
    font: Tokens.body
    delegate: ItemDelegate {
        id: option
        required property int index
        required property var modelData
        width: control.popup.width - control.popup.leftPadding - control.popup.rightPadding
        implicitHeight: Tokens.controlHeight
        text: modelData
        highlighted: control.highlightedIndex === index
        leftPadding: Tokens.space12
        rightPadding: Tokens.space12
        contentItem: Text {
            text: option.text
            font: control.font
            color: option.highlighted ? Tokens.textOnPrimary : Tokens.textPrimary
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: Tokens.radiusS
            color: option.highlighted ? Tokens.primary : option.hovered ? Tokens.primaryContainer : "transparent"
        }
    }
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: Tokens.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        leftPadding: Tokens.space12
        rightPadding: Tokens.space24
    }
    popup: Popup {
        transformOrigin: Item.Top
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight + padding * 2, Tokens.launcherHeight)
        padding: Tokens.space4
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.springEffectsFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springEffectsFast.curve
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
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            // No hidden delegates or internal highlight-tracker animations.
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            highlightMoveVelocity: -1
            highlightResizeVelocity: -1
            highlightMoveDuration: 0
            highlightResizeDuration: 0
        }
        background: Surface {
            padding: 0
            material: "acrylic"
        }
    }
    background: Rectangle {
        radius: Tokens.radiusM
        color: control.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
        border.width: control.visualFocus ? Tokens.space2 : 0
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
