// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    spacing: Tokens.space16
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("shell.scene.performance"), I18n.t("shell.scene.balanced"), I18n.t("shell.scene.saver")]
        currentIndex: Shell.scenes.activeId === "performance" ? 0 : Shell.scenes.activeId === "balanced" ? 1 : 2
        Accessible.name: I18n.t("shell.scene.select")
        onActivated: Shell.scenes.select(["performance", "balanced", "power-saver"][currentIndex])
    }
    Label {
        text: I18n.t("shell.scene.disclosure")
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font: Tokens.caption
        color: Tokens.textSecondary
    }
    PolicyControls {
        Layout.fillWidth: true
    }
}
