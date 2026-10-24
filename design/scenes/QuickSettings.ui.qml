// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 600
    height: 620
    SurfaceForm {
        anchors.centerIn: parent
        width: 432
        height: form.implicitHeight + Tokens.space32
    }
    QuickSettingsForm {
        id: form
        anchors.centerIn: parent
        width: 400
    }
}
