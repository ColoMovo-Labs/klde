// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import KLDE.Backends

Surface {
    id: root
    property bool compact: false
    implicitWidth: workspaceRow.implicitWidth + Tokens.space16
    width: implicitWidth
    implicitHeight: compact ? Tokens.ribbonHeight : Tokens.controlHeight + Tokens.space16
    height: implicitHeight
    padding: Tokens.space8
    cornerRadius: Tokens.radiusPill

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: Tokens.space4
        Repeater {
            model: Shell.windowManager.workspaces
            delegate: Button {
                id: workspaceButton
                required property var modelData
                readonly property bool selected: modelData.id === Shell.windowManager.activeWorkspace
                readonly property string modeLabel: modelData.layout === WindowManagerBackend.Floating ? I18n.t("shell.workspace.floating") : modelData.layout === WindowManagerBackend.Tiled ? I18n.t("shell.workspace.tiled") : modelData.layout === WindowManagerBackend.Mixed ? I18n.t("shell.workspace.mixed") : I18n.t("shell.workspace.custom")
                width: selected ? Tokens.controlHeight + Tokens.space12 : Tokens.densityMode === 2 ? Tokens.space16 : Tokens.space24
                height: root.compact ? Tokens.ribbonHeight - Tokens.space8 : Tokens.controlHeight
                text: selected ? modelData.name + " " + ["F", "T", "M", "S"][Math.min(modelData.layout, 3)] : Tokens.densityMode === 2 ? "•" : modelData.name
                font: Tokens.label
                Accessible.name: I18n.t("shell.workspace.accessible").arg(modelData.name).arg(modeLabel).arg(selected ? I18n.t("common.selected") : "")
                ToolTip.visible: hovered
                ToolTip.text: modeLabel
                onClicked: Shell.windowManager.activateWorkspace(modelData.id)
                background: Rectangle {
                    radius: workspaceButton.selected ? Tokens.radiusPill : Tokens.radiusM
                    color: workspaceButton.selected ? Tokens.primaryContainer : "transparent"
                    border.width: workspaceButton.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Tokens.motionFast
                        easing.type: Tokens.emphasizedDecelerate
                    }
                }
            }
        }
    }
}
