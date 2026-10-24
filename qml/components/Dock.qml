// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import KLDE.Backends

Surface {
    id: root
    readonly property bool nativeInputSurface: true
    signal launcherRequested
    signal settingsRequested
    width: form.row.implicitWidth + Tokens.space24
    height: Tokens.dockHeight
    padding: 0
    cornerRadius: Tokens.radiusXL
    material: "glass"
    function focusLauncher(): void {
        form.launcherButton.forceActiveFocus();
    }
    function activateApp(appId: string, index: int): void {
        if (appId === "settings")
            settingsRequested();
        else
            Shell.launch(appId);
    }
    DockForm {
        id: form
        anchors.fill: parent
        decorationVisible: false
        applications: Shell.applications
        actionTarget: root
    }
    Connections {
        target: form.launcherButton
        function onClicked(): void {
            root.launcherRequested();
        }
    }
}
