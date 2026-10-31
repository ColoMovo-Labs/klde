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
        Layout.fillWidth: true
        spacing: Tokens.space8
        SliderCard {
            objectName: "settingsVolume"
            Layout.fillWidth: true
            label: I18n.t("shell.effects.volume")
            iconName: "volume"
            value: Shell.system.volume
            onValueRequested: requestedValue => Shell.system.volume = requestedValue
        }
        MockBadge {
            path: "audio.volume"
        }
    }
    StateSlider {
        label: I18n.t("lab.module.microphone")
        iconName: "microphone"
        path: "audio.microphone"
        visible: Shell.state.snapshot.capabilities.microphone
    }
    Label {
        text: I18n.t("settings.sound.keys")
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
