// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    property alias welcome: interactiveForm
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
        id: interactiveForm
        anchors.fill: parent
        anchors.margins: Tokens.space64
    }
    states: [
        State {
            name: "light"
            PropertyChanges {
                target: Tokens
                darkMode: false
            }
        },
        State {
            name: "dark"
            PropertyChanges {
                target: Tokens
                darkMode: true
            }
        }
    ]
}
