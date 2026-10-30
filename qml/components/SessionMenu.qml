// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "sessionMenu"
    width: Math.min(Tokens.panelWidth, parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    height: contentItem.implicitHeight + padding * 2
    contentItem: ColumnLayout {
        spacing: Tokens.space16
        Label {
            text: I18n.t("session.logout.title")
            font: Tokens.title
            color: Tokens.textPrimary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Label {
            text: I18n.t("session.logout.detail")
            font: Tokens.body
            color: Tokens.textSecondary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            ActionButton {
                text: I18n.t("session.logout.cancel")
                onClicked: root.close()
            }
            ActionButton {
                objectName: "confirmLogout"
                text: I18n.t("session.logout.confirm")
                enabled: Shell.session.managed
                onClicked: Shell.session.logout()
            }
        }
    }
}
