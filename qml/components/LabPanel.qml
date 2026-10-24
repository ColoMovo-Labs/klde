// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

ShellPopup {
    id: root
    property Component footer: null
    required property string heading
    default property alias body: bodyColumn.data
    property alias subtitle: header.subtitle
    width: Math.min(Tokens.settingsWidth, parent ? parent.width - Tokens.space32 : Tokens.settingsWidth)
    height: Math.min(bodyColumn.implicitHeight + header.implicitHeight + footerLoader.implicitHeight + padding * 2 + Tokens.space16, parent ? parent.height - Tokens.space32 : Tokens.settingsHeight)
    Connections {
        target: header.closeButton
        function onClicked(): void {
            root.close();
        }
    }
    contentItem: ColumnLayout {
        spacing: Tokens.space16
        PanelHeaderForm {
            id: header
            Layout.fillWidth: true
            title: root.heading
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
        Loader {
            id: footerLoader
            active: root.footer !== null
            visible: active
            sourceComponent: root.footer
            Layout.fillWidth: true
        }
    }
}
