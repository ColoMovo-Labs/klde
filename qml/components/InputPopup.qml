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
    signal settingsRequested
    width: Math.min(Tokens.panelWidth, parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    height: column.implicitHeight + padding * 2
    contentItem: ColumnLayout {
        id: column
        spacing: Tokens.space12
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: I18n.t("input.preview")
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
            text: I18n.t("input.disclosure")
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
                text: (modelData.id === Shell.input.currentId ? "✓ " : "") + I18n.t(modelData.labelId)
                emphasized: modelData.id === Shell.input.currentId
                onClicked: Shell.input.selectPreview(modelData.id)
            }
        }
        Label {
            text: I18n.t(Shell.input.engineAvailable ? "input.detected" : "input.unavailable")
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
