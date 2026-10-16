// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    implicitHeight: Tokens.controlHeight
    font: Tokens.body
    background: Rectangle {
        radius: Tokens.radiusM
        color: control.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
        border.width: control.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
}
