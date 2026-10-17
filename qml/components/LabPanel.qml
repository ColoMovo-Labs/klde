// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellPopup {
    id: root
    required property string heading
    default property alias body: bodyColumn.data
    property alias subtitle: subtitle.text
    width: Math.min(Tokens.settingsWidth, parent ? parent.width - Tokens.space32 : Tokens.settingsWidth)
    height: Math.min(bodyColumn.implicitHeight + header.implicitHeight + padding * 2 + Tokens.space16, parent ? parent.height - Tokens.space32 : Tokens.settingsHeight)
    contentItem: ColumnLayout {
        spacing: Tokens.space16
        RowLayout {
            id: header
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    text: root.heading
                    font: Tokens.title
                    color: Tokens.textPrimary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Label {
                    id: subtitle
                    visible: text.length > 0
                    font: Tokens.caption
                    color: Tokens.textSecondary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
            IconButton {
                iconName: "close"
                text: I18n.t("lab.close")
                onClicked: root.close()
            }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true
            ColumnLayout {
                id: bodyColumn
                width: scroll.availableWidth
                spacing: Tokens.rowGap
            }
        }
    }
}
