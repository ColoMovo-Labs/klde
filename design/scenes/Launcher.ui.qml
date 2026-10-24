// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    property alias launcher: launcherForm
    property alias dock: previewDock
    property alias applications: apps
    width: 1000
    height: 760
    MockApplications {
        id: apps
    }
    SurfaceForm {
        anchors.centerIn: parent
        width: Tokens.launcherWidth
        height: body.height + Tokens.space32
    }
    ColumnLayout {
        id: body
        anchors.centerIn: parent
        width: Tokens.launcherWidth - Tokens.space32
        height: Tokens.controlHeight + Tokens.space12 + Math.max(1, Math.ceil(apps.count / Math.max(2, Math.floor(width / Tokens.launcherGridMinimumCell)))) * Tokens.launcherGridCellHeight + Tokens.dockHeight + Tokens.space24
        spacing: Tokens.space12
        LauncherForm {
            id: launcherForm
            Layout.fillWidth: true
            Layout.fillHeight: true
            applications: apps
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Tokens.surfaceEdge
        }
        DockForm {
            id: previewDock
            Layout.alignment: Qt.AlignHCenter
            applications: apps
            decorationVisible: false
        }
    }
}
