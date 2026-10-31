// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    readonly property var caps: Shell.windowManager.capabilities
    readonly property var modes: [WindowManagerBackend.Floating, WindowManagerBackend.ClassicTiling, WindowManagerBackend.Scrolling]
    spacing: Tokens.space16
    Label {
        text: I18n.t(root.caps.workspaceLayouts ? "settings.workspaces.help" : "settings.workspaces.unsupported")
        font: Tokens.body
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Repeater {
        model: Shell.windowManager.workspaces
        delegate: RowLayout {
            id: workspaceRow
            required property var modelData
            Layout.fillWidth: true
            spacing: Tokens.space12
            Label {
                text: I18n.t("settings.workspaces.name").arg(workspaceRow.modelData.name)
                font: workspaceRow.modelData.id === Shell.windowManager.activeWorkspace ? Tokens.label : Tokens.body
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            ChoiceBox {
                Layout.preferredWidth: Tokens.panelWidth / 2
                enabled: root.caps.workspaceLayouts === true
                model: [I18n.t("shell.workspace.floating"), I18n.t("shell.workspace.tiled"), I18n.t("lab.workspace.scrolling")]
                currentIndex: root.modes.indexOf(workspaceRow.modelData.layout)
                Accessible.name: I18n.t("settings.workspaces.name").arg(workspaceRow.modelData.name)
                onActivated: Shell.windowManager.setWorkspaceLayout(workspaceRow.modelData.id, root.modes[currentIndex])
            }
        }
    }
}
