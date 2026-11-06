// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    signal candidateRequested
    spacing: Tokens.space16
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
        text: I18n.t(Shell.input.engineAvailable ? Shell.input.simulated ? "input.detected" : "input.native.ready" : "input.unavailable")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    Label {
        text: I18n.t(Shell.input.simulated ? "input.disclosure" : "input.native.disclosure")
        font: Tokens.caption
        color: Tokens.textSecondary
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Repeater {
            model: Shell.input.methods
            delegate: ActionButton {
                id: methodButton
                required property var modelData
                Layout.fillWidth: true
                text: (modelData.name || I18n.t(modelData.labelId))
                emphasized: modelData.id === Shell.input.currentId
                Accessible.name: text
                enabled: Shell.input.simulated || Shell.input.switchingSupported
                onClicked: Shell.input.simulated ? Shell.input.selectPreview(modelData.id) : Shell.input.requestSwitch(modelData.id)
            }
        }
    }
    ActionButton {
        visible: !Shell.input.simulated
        enabled: Shell.input.engineAvailable
        text: I18n.t("input.native.configure")
        onClicked: Shell.input.configure()
    }
    Switch {
        visible: Shell.input.simulated
        text: I18n.t("lab.input.simplified")
        checked: Shell.state.snapshot.input.simplified
        onToggled: Shell.state.requestValue("input.simplified", checked)
    }
    ActionButton {
        visible: Shell.input.simulated
        text: I18n.t("lab.candidate.title")
        onClicked: root.candidateRequested()
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
    SystemSettingsButton {
        panel: "system"
        label: I18n.t("settings.bridge.region")
    }
}
