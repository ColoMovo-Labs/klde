// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import KLDE.Backends

Surface {
    width: workspaceRow.implicitWidth + Tokens.space24
    height: Tokens.controlHeight + Tokens.space16
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
                readonly property string modeLabel: modelData.layout === WindowManagerBackend.Floating ? qsTr("Floating") : modelData.layout === WindowManagerBackend.Tiled ? qsTr("Tiled") : modelData.layout === WindowManagerBackend.Mixed ? qsTr("Mixed") : qsTr("Custom")
                width: Tokens.controlHeight + Tokens.space12
                height: Tokens.controlHeight
                text: modelData.name + " " + modeLabel.slice(0, 1)
                font: Tokens.label
                Accessible.name: qsTr("Workspace %1, %2%3").arg(modelData.name).arg(modeLabel).arg(selected ? qsTr(", selected") : "")
                ToolTip.visible: hovered
                ToolTip.text: modeLabel
                onClicked: Shell.windowManager.activateWorkspace(modelData.id)
                background: Rectangle {
                    radius: workspaceButton.selected ? Tokens.radiusL : Tokens.radiusS
                    color: workspaceButton.selected ? Tokens.primaryContainer : "transparent"
                    border.width: workspaceButton.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                }
            }
        }
    }
}
