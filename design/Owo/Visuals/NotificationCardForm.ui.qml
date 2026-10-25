// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string sourceName: "owoDE"
    property string heading: "欢迎回来"
    property string body: "这是一条模拟通知。"
    property int severity: 0
    property alias dismissButton: dismissButton
    implicitHeight: content.implicitHeight + Tokens.space24
    radius: root.severity === 2 ? Tokens.radiusM : Tokens.radiusL
    color: root.severity === 2 ? Tokens.surfaceContainerHigh : Tokens.surfaceContainer
    border.width: root.severity === 2 ? 1 : 0
    border.color: Tokens.error
    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Tokens.space12
        Glyph {
            name: root.severity === 2 ? "info" : "bell"
            Layout.preferredWidth: Tokens.iconM
            Layout.preferredHeight: Tokens.iconM
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space4
            Text {
                text: root.sourceName
                font: Tokens.caption
                color: Tokens.textSecondary
            }
            Text {
                text: root.heading
                font: Tokens.label
                color: root.severity === 2 ? Tokens.error : Tokens.textPrimary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Text {
                text: root.body
                font: Tokens.body
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        SmallButton {
            id: dismissButton
            iconName: "close"
            text: "关闭 / Dismiss"
        }
    }
}
