// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import KLDE.Backends

Surface {
    id: root
    signal launcherRequested
    signal settingsRequested
    width: dockRow.implicitWidth + Tokens.space24
    height: Tokens.dockHeight
    padding: Tokens.space12
    cornerRadius: Tokens.radiusXL
    function focusLauncher(): void {
        launcherButton.forceActiveFocus();
    }

    Row {
        id: dockRow
        anchors.centerIn: parent
        spacing: Tokens.space6
        IconButton {
            id: launcherButton
            objectName: "launcherButton"
            width: Tokens.dockItem
            height: Tokens.dockItem
            iconName: "klde"
            text: qsTr("Open launcher")
            emphasized: true
            onClicked: root.launcherRequested()
        }
        Rectangle {
            width: Tokens.space1
            height: Tokens.space24
            anchors.verticalCenter: parent.verticalCenter
            color: Tokens.outline
            opacity: Tokens.mutedOpacity
        }
        Repeater {
            model: Shell.applications
            delegate: Button {
                id: appButton
                required property string appId
                required property string displayName
                required property string iconName
                required property bool running
                required property bool active
                width: Tokens.dockItem
                height: Tokens.dockItem
                Accessible.name: displayName + (active ? qsTr(", active") : running ? qsTr(", running") : "")
                ToolTip.visible: hovered
                ToolTip.text: displayName
                onClicked: appId === "settings" ? root.settingsRequested() : Shell.launch(appId)
                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        width: Tokens.dockIcon
                        height: Tokens.dockIcon
                        name: appButton.iconName
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: appButton.active ? Tokens.space12 : Tokens.space4
                        height: Tokens.space3
                        radius: Tokens.radiusPill
                        color: Tokens.primary
                        visible: appButton.running
                    }
                }
                background: Rectangle {
                    radius: appButton.hovered || appButton.active ? Tokens.radiusL : Tokens.radiusM
                    color: appButton.down || appButton.active ? Tokens.primaryContainer : appButton.hovered ? Tokens.surfaceContainer : "transparent"
                    border.width: appButton.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.motionFast
                        }
                    }
                }
            }
        }
    }
}
