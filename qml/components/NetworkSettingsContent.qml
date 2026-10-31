// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    readonly property var snapshot: Shell.state.snapshot
    spacing: Tokens.space16
    Switch {
        objectName: "settingsWifi"
        text: I18n.t("shell.network.wifi")
        checked: Shell.system.wifi
        onToggled: Shell.system.wifi = checked
    }
    Label {
        text: !root.snapshot.network.enabled ? I18n.t("settings.network.off") : root.snapshot.network.connected ? I18n.t("settings.network.connected").arg(root.snapshot.network.ssid) : I18n.t("lab.network.offline")
        font: Tokens.body
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Switch {
        objectName: "settingsBluetooth"
        text: I18n.t("shell.network.bluetooth")
        enabled: root.snapshot.capabilities.bluetooth
        checked: Shell.system.bluetooth
        onToggled: Shell.system.bluetooth = checked
    }
    Label {
        visible: !root.snapshot.capabilities.bluetooth
        text: I18n.t("settings.network.no-bluetooth")
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
