// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    heading: I18n.t("android.title")
    subtitle: I18n.t("android.mock")
    Switch {
        text: I18n.t("android.available")
        checked: Shell.waydroid.state.available
        onToggled: Shell.state.requestValue("waydroid.available", checked)
    }
    Switch {
        text: I18n.t("android.index")
        checked: Shell.waydroid.state.indexApps
        onToggled: Shell.state.requestValue("waydroid.indexApps", checked)
    }
    Label {
        text: I18n.t(!Shell.waydroid.state.available ? "android.unavailable" : Shell.waydroid.state.running ? "android.running" : "android.stopped")
        color: Tokens.textSecondary
        font: Tokens.body
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    ActionButton {
        text: I18n.t(Shell.waydroid.state.running ? "android.stop" : "android.start")
        enabled: Shell.waydroid.state.available
        Layout.fillWidth: true
        onClicked: Shell.waydroid.setRunning(!Shell.waydroid.state.running)
    }
}
