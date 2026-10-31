// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    spacing: Tokens.space16
    RowLayout {
        spacing: Tokens.space16
        Image {
            source: "qrc:/assets/branding/owode-logo.png"
            sourceSize: Qt.size(Tokens.iconL * 2, Tokens.iconL * 2)
            Layout.preferredWidth: Tokens.iconL * 2
            Layout.preferredHeight: Tokens.iconL * 2
            fillMode: Image.PreserveAspectFit
            Accessible.ignored: true
        }
        ColumnLayout {
            spacing: Tokens.space4
            Label {
                text: Branding.formalName
                font: Tokens.headline
                color: Tokens.textPrimary
            }
            Label {
                text: I18n.t("settings.about.version").arg(Qt.application.version).arg(Branding.codename)
                font: Tokens.body
                color: Tokens.textSecondary
            }
        }
    }
    Label {
        objectName: "settingsAboutSession"
        text: I18n.t("settings.about.session").arg(Shell.session.compositor.length > 0 ? Shell.session.compositor : I18n.t("settings.about.preview")).arg(Shell.displayServer.platform)
        font: Tokens.body
        color: Tokens.textPrimary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Label {
        objectName: "settingsAboutStore"
        text: Shell.settings.readOnly ? I18n.t("settings.about.store.readonly").arg(Shell.settings.path) : Shell.settings.persistent ? I18n.t("settings.about.store.file").arg(Shell.settings.path).arg(Shell.settings.version) : I18n.t("settings.about.store.memory")
        textFormat: Text.PlainText
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WrapAnywhere
        Layout.fillWidth: true
    }
}
