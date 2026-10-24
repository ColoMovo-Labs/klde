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
    material: "glass"
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
            iconName: Branding.iconName
            text: I18n.t("shell.launcher.open")
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
                scale: appButton.down ? Tokens.pressScale : appButton.hovered ? Tokens.hoverScale : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: Tokens.springSpatialMicro.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springSpatialMicro.curve
                    }
                }
                Accessible.name: I18n.s(displayName) + (active ? I18n.t("common.active") : running ? I18n.t("common.running") : "")
                ToolTip.visible: hovered
                ToolTip.text: I18n.s(displayName)
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
                        opacity: appButton.running ? 1 : 0
                        Behavior on width {
                            NumberAnimation {
                                duration: Tokens.springSpatialMicro.duration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Tokens.springSpatialMicro.curve
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Tokens.springEffectsFast.duration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Tokens.springEffectsFast.curve
                            }
                        }
                    }
                }
                background: Rectangle {
                    radius: appButton.hovered || appButton.active ? Tokens.radiusL : Tokens.radiusM
                    color: appButton.down || appButton.active ? Tokens.primaryContainer : appButton.hovered ? Tokens.surfaceContainer : "transparent"
                    border.width: appButton.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.springEffectsFast.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Tokens.springEffectsFast.curve
                        }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: Tokens.springSpatialMicro.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Tokens.springSpatialMicro.curve
                        }
                    }
                }
            }
        }
    }
}
