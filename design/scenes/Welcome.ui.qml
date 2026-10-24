// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 1440
    height: 900
    BackgroundForm {
        anchors.fill: parent
    }
    SurfaceForm {
        anchors.fill: parent
        anchors.margins: Tokens.space32
    }
    WelcomeBrandForm {
        anchors.fill: parent
        anchors.margins: Tokens.space64
    }
}
