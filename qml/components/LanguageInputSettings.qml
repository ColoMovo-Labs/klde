// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "languageInputSettings"
    modal: true
    width: Tokens.settingsWidth
    height: Math.min(Tokens.settingsHeight, parent ? parent.height - Tokens.space32 * 2 : Tokens.settingsHeight)
    contentItem: ScrollView {
        id: scroll
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            width: scroll.availableWidth
            spacing: Tokens.space16
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: I18n.t("language.title")
                    font: Tokens.title
                    color: Tokens.textPrimary
                    Layout.fillWidth: true
                }
                IconButton {
                    iconName: "close"
                    text: I18n.t("language.close")
                    onClicked: root.close()
                }
            }
            Label {
                text: I18n.t("language.session")
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Label {
                text: I18n.t("language.locale")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ChoiceBox {
                objectName: "localeSelector"
                Layout.fillWidth: true
                model: [I18n.t("language.english"), I18n.t("language.chinese")]
                currentIndex: Shell.language.locale === "zh_CN" ? 1 : 0
                Accessible.name: I18n.t("language.locale")
                onActivated: Shell.language.setLocale(currentIndex === 1 ? "zh_CN" : "en")
            }
            Label {
                text: I18n.t("language.voice")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ChoiceBox {
                objectName: "voiceSelector"
                Layout.fillWidth: true
                model: [I18n.t("language.standard"), I18n.t("language.cute")]
                currentIndex: Shell.language.voice === "cute" ? 1 : 0
                Accessible.name: I18n.t("language.voice")
                onActivated: Shell.language.setVoice(currentIndex === 1 ? "cute" : "standard")
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: sample.implicitHeight + Tokens.space32
                radius: Tokens.radiusXL
                color: Tokens.primaryContainer
                Label {
                    id: sample
                    anchors.fill: parent
                    anchors.margins: Tokens.space16
                    text: I18n.t("shell.quick.title") + "\n" + I18n.t("friendly.weather.unavailable")
                    font: Tokens.body
                    color: Tokens.textPrimary
                    wrapMode: Text.WordWrap
                }
            }
            Label {
                text: I18n.t("input.engine")
                font: Tokens.title
                color: Tokens.textPrimary
            }
            Label {
                text: I18n.t(Shell.input.engineAvailable ? "input.detected" : "input.unavailable")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            Label {
                text: I18n.t("input.disclosure")
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: Shell.input.methods
                    delegate: ActionButton {
                        id: methodButton
                        required property var modelData
                        Layout.fillWidth: true
                        text: I18n.t(modelData.labelId)
                        emphasized: modelData.id === Shell.input.currentId
                        Accessible.name: text + ", " + I18n.t("input.preview")
                        onClicked: Shell.input.selectPreview(modelData.id)
                    }
                }
            }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.controlHeight * 2
                placeholderText: I18n.t("language.input-test")
                Accessible.name: I18n.t("language.input-test")
                wrapMode: TextEdit.Wrap
                font: Tokens.body
            }
            Label {
                text: I18n.t("input.theme")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            Label {
                text: I18n.t("input.theme.note")
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }
}
