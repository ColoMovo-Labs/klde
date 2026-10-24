// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "weatherSettings"
    modal: true
    width: Math.min(Tokens.settingsWidth, parent ? parent.width - Tokens.space32 : Tokens.settingsWidth)
    height: Math.min(contentColumn.implicitHeight + padding * 2, parent ? parent.height - Tokens.space32 * 2 : Tokens.settingsHeight)
    contentItem: ScrollView {
        id: scroll
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            id: contentColumn
            width: scroll.availableWidth
            spacing: Tokens.space16
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: I18n.t("privacy.weather.title")
                    font: Tokens.title
                    color: Tokens.textPrimary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                IconButton {
                    iconName: "close"
                    text: I18n.t("privacy.weather.close")
                    onClicked: root.close()
                }
            }
            Label {
                text: I18n.t("privacy.weather.disclosure")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font: Tokens.body
                color: Tokens.textPrimary
            }
            Label {
                text: "<a href='https://uapis.cn/docs/getting-started/privacy-policy'>" + I18n.t("privacy.weather.terms") + "</a>"
                textFormat: Text.RichText
                onLinkActivated: link => Qt.openUrlExternally(link)
                color: Tokens.textSecondary
                font: Tokens.label
            }
            TextField {
                id: city
                Layout.fillWidth: true
                placeholderText: I18n.t("shell.weather.city")
                Accessible.name: I18n.t("shell.weather.city.accessible")
                maximumLength: 128
            }
            ChoiceBox {
                id: language
                model: ["English", "中文"]
                Layout.fillWidth: true
                Accessible.name: I18n.t("shell.weather.language")
            }
            RowLayout {
                Layout.fillWidth: true
                ActionButton {
                    text: I18n.t("privacy.weather.enable")
                    enabled: city.text.trim().length > 0 && !Shell.weatherService.busy
                    onClicked: Shell.weatherService.enableOnline(city.text, language.currentIndex === 0 ? "en" : "zh")
                }
                ActionButton {
                    text: I18n.t("privacy.weather.disable")
                    enabled: Shell.weatherService.onlineEnabled
                    onClicked: Shell.weatherService.disableOnline()
                }
            }
            Label {
                text: I18n.s(Shell.weatherService.attribution) + " · " + I18n.t("weather.status." + Shell.weatherService.status) + (Shell.weatherService.stale ? I18n.t("shell.weather.stale") : "")
                font: Tokens.label
                color: Tokens.textPrimary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Label {
                text: I18n.s(Shell.weatherService.message)
                visible: text.length > 0
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            ActionButton {
                text: I18n.t("shell.weather.refresh")
                enabled: Shell.weatherService.onlineEnabled && !Shell.weatherService.busy
                onClicked: Shell.weatherService.refresh()
            }
            Label {
                text: I18n.t("privacy.weather.schedule")
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}
