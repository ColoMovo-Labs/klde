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
    Label {
        text: I18n.t("shell.shortcut.title")
        font: Tokens.title
        color: Tokens.textPrimary
    }
    Label {
        text: I18n.t("shell.shortcut.help")
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font: Tokens.caption
        color: Tokens.textSecondary
    }
    Repeater {
        model: Shell.shortcuts.actions
        delegate: RowLayout {
            id: shortcutRow
            required property var modelData
            Layout.fillWidth: true
            Label {
                text: I18n.s(shortcutRow.modelData.label)
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            TextField {
                Layout.preferredWidth: Tokens.panelWidth / 2
                text: shortcutRow.modelData.sequence
                Accessible.name: I18n.t("shell.shortcut.field").arg(I18n.s(shortcutRow.modelData.label))
                onEditingFinished: Shell.shortcuts.rebind(shortcutRow.modelData.id, text)
            }
        }
    }
    Label {
        text: I18n.s(Shell.shortcuts.lastError)
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Tokens.error
        visible: text.length > 0
    }
    ActionButton {
        text: I18n.t("shell.shortcut.reset")
        onClicked: Shell.shortcuts.resetDefaults()
    }
}
