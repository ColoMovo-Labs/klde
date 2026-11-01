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
    property bool decorationVisible: true
    property bool highlighted: false
    property bool showSource: true
    property string iconName: root.severity === 2 ? "info" : "bell"
    property int bodyFormat: Text.PlainText
    property int bodyMaximumLines: 32767
    property alias bodyLabel: bodyLabel
    property alias dismissButton: dismissButton
    implicitHeight: content.implicitHeight + Tokens.space24
    radius: root.severity === 2 ? Tokens.radiusM : Tokens.radiusL
    color: root.decorationVisible ? root.severity === 2 ? Tokens.surfaceContainerHigh : Tokens.surfaceContainer : "transparent"
    border.width: root.decorationVisible ? root.highlighted ? Tokens.space2 : root.severity === 2 ? Tokens.space1 : 0 : 0
    border.color: root.highlighted ? Tokens.primary : Tokens.error
    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Tokens.space12
        Glyph {
            name: root.iconName
            Layout.preferredWidth: Tokens.iconM
            Layout.preferredHeight: Tokens.iconM
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space4
            Text {
                visible: root.showSource && root.sourceName.length > 0
                text: root.sourceName
                textFormat: Text.PlainText
                Layout.fillWidth: true
                elide: Text.ElideRight
                font: Tokens.caption
                color: Tokens.textSecondary
            }
            Text {
                text: root.heading
                visible: root.heading.length > 0
                textFormat: Text.PlainText
                maximumLineCount: 2
                elide: Text.ElideRight
                font: Tokens.label
                color: root.severity === 2 ? Tokens.error : Tokens.textPrimary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Text {
                id: bodyLabel
                visible: root.body.length > 0
                text: root.body
                textFormat: root.bodyFormat
                maximumLineCount: root.bodyMaximumLines
                elide: Text.ElideRight
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
