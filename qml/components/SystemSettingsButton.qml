// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import KLDE.Backends

ColumnLayout {
    id: root
    required property string panel
    property string label: I18n.t("settings.bridge.open")
    property string missingMessage: I18n.t("settings.bridge.missing")
    readonly property bool installed: Shell.systemSettings.entries.some(entry => entry.id === root.panel && entry.available)
    spacing: Tokens.space4
    ActionButton {
        objectName: "systemSettings-" + root.panel
        text: root.label
        enabled: Shell.systemSettings.enabled && root.installed
        onClicked: Shell.systemSettings.open(root.panel)
    }
    Label {
        visible: Shell.systemSettings.enabled && !root.installed
        text: root.missingMessage
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Component.onCompleted: Shell.systemSettings.refresh()
}
