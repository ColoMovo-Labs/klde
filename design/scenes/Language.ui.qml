// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    property alias language: interactiveForm
    width: 1440
    height: 900
    Rectangle {
        anchors.fill: parent
        color: Tokens.background
    }
    LanguageForm {
        id: interactiveForm
        anchors.centerIn: parent
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
