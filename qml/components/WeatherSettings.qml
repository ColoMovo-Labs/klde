// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "weatherSettings"
    modal: true
    width: Tokens.settingsWidth
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
                    text: qsTr("A little sky, with your permission.")
                    font: Tokens.title
                    color: Tokens.textPrimary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                IconButton {
                    iconName: "close"
                    text: qsTr("Close weather settings")
                    onClicked: root.close()
                }
            }
            Label {
                text: qsTr("Mock weather is the default. Enabling experimental online weather sends the city you enter and your connection's IP address to uapis.cn. No automatic location lookup is used. The provider has its own terms, privacy policy and shared request quota.")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font: Tokens.body
                color: Tokens.textPrimary
            }
            Label {
                text: "<a href='https://uapis.cn/docs/getting-started/privacy-policy'>Provider terms &amp; privacy</a>"
                textFormat: Text.RichText
                onLinkActivated: link => Qt.openUrlExternally(link)
                color: Tokens.textSecondary
                font: Tokens.label
            }
            TextField {
                id: city
                Layout.fillWidth: true
                placeholderText: qsTr("City name")
                Accessible.name: qsTr("Weather city, entered manually")
                maximumLength: 128
            }
            ComboBox {
                id: language
                model: ["English", "中文"]
                Layout.fillWidth: true
                Accessible.name: qsTr("Weather language")
            }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: qsTr("Enable online weather")
                    enabled: city.text.trim().length > 0 && !Shell.weatherService.busy
                    onClicked: Shell.weatherService.enableOnline(city.text, language.currentIndex === 0 ? "en" : "zh")
                }
                Button {
                    text: qsTr("Use mock / disconnect")
                    enabled: Shell.weatherService.onlineEnabled
                    onClicked: Shell.weatherService.disableOnline()
                }
            }
            Label {
                text: Shell.weatherService.attribution + " · " + Shell.weatherService.status + (Shell.weatherService.stale ? qsTr(" · stale") : "")
                font: Tokens.label
                color: Tokens.textPrimary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Label {
                text: Shell.weatherService.message
                visible: text.length > 0
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Button {
                text: qsTr("Refresh when allowed")
                enabled: Shell.weatherService.onlineEnabled && !Shell.weatherService.busy
                onClicked: Shell.weatherService.refresh()
            }
            Label {
                text: qsTr("The preview keeps an in-memory cache, waits at least 15 minutes between requests and normally refreshes every two hours. Quota exhaustion stops automatic retries. Location and consent are not persisted in this preview.")
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}
