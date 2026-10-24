// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 800
    height: 240
    MockApplications {
        id: apps
    }
    DockForm {
        anchors.centerIn: parent
        applications: apps
    }
}
