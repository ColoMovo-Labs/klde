// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string label: "Application"
    property string detail: ""
    property string glyph: "folder"
    property bool selected: false
    property bool listMode: false
    hoverEnabled: true
    Accessible.name: label + ", " + detail
    background: Rectangle {
        radius: Tokens.radiusL
        color: root.selected || root.hovered ? Tokens.primaryContainer : "transparent"
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
    contentItem: Item {
        Glyph {
            id: appIcon
            width: Tokens.iconL
            height: Tokens.iconL
            x: root.listMode ? Tokens.space12 : (parent.width - width) / 2
            y: root.listMode ? (parent.height - height) / 2 : Tokens.space6
            name: root.glyph
        }
        Column {
            x: root.listMode ? appIcon.x + appIcon.width + Tokens.space16 : Tokens.space4
            y: root.listMode ? (parent.height - height) / 2 : appIcon.y + appIcon.height + Tokens.space8
            width: root.listMode ? parent.width - x - Tokens.space12 : parent.width - Tokens.space8
            spacing: Tokens.space4
            Text {
                objectName: "applicationLabel"
                width: parent.width
                text: root.label
                textFormat: Text.PlainText
                font: Tokens.label
                color: Tokens.textPrimary
                horizontalAlignment: root.listMode ? Text.AlignLeft : Text.AlignHCenter
                elide: Text.ElideRight
            }
            Text {
                objectName: "applicationDetail"
                width: parent.width
                visible: root.listMode
                text: root.detail
                textFormat: Text.PlainText
                font: Tokens.caption
                color: Tokens.textSecondary
                elide: Text.ElideRight
            }
        }
    }
}
