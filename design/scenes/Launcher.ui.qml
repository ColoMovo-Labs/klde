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
        width: 680
        height: 620
    }
    ColumnLayout {
        anchors.centerIn: parent
        width: 632
        height: 572
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
