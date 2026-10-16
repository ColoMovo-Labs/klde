// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    implicitHeight: Tokens.controlHeight
    font: Tokens.body
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
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight + padding * 2, Tokens.launcherHeight)
        padding: Tokens.space4
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
        }
    }
    background: Rectangle {
        radius: Tokens.radiusM
        color: control.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
        border.width: control.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
}
