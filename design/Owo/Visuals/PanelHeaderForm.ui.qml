// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property alias title: titleText.text
    property alias subtitle: subtitleText.text
    property alias closeButton: closeButton
    spacing: Tokens.space12
    ColumnLayout {
        Layout.fillWidth: true
        Text {
            id: titleText
            Layout.fillWidth: true
            font: Tokens.title
            color: Tokens.textPrimary
            wrapMode: Text.WordWrap
        }
        Text {
            id: subtitleText
            visible: text.length > 0
            Layout.fillWidth: true
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
        }
    }
    SmallButton {
        id: closeButton
        iconName: "close"
        text: "关闭 / Close"
    }
}
