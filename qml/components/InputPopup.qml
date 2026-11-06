// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "inputPopup"
    onOpened: Shell.input.refresh()
    signal settingsRequested
    width: Math.min(Tokens.panelWidth, parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    height: column.implicitHeight + padding * 2
    contentItem: ColumnLayout {
        id: column
        spacing: Tokens.space12
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: I18n.t(Shell.input.simulated ? "input.preview" : "input.engine")
                font: Tokens.title
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            IconButton {
                iconName: "close"
                text: I18n.t("input.close")
                onClicked: root.close()
            }
        }
        Label {
            text: I18n.t(Shell.input.simulated ? "input.disclosure" : "input.native.disclosure")
            font: Tokens.caption
            color: Tokens.textSecondary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Repeater {
            model: Shell.input.methods
            delegate: ActionButton {
                required property var modelData
                Layout.fillWidth: true
                text: (modelData.id === Shell.input.currentId ? "✓ " : "") + (modelData.name || I18n.t(modelData.labelId))
                emphasized: modelData.id === Shell.input.currentId
                enabled: Shell.input.simulated || Shell.input.switchingSupported
                onClicked: Shell.input.simulated ? Shell.input.selectPreview(modelData.id) : Shell.input.requestSwitch(modelData.id)
            }
        }
        Label {
            text: I18n.t(Shell.input.engineAvailable ? Shell.input.simulated ? "input.detected" : "input.native.ready" : "input.unavailable")
            font: Tokens.caption
            color: Tokens.textSecondary
        }
        ActionButton {
            Layout.fillWidth: true
            text: I18n.t("input.settings")
            onClicked: {
                root.close();
                root.settingsRequested();
            }
        }
    }
}
