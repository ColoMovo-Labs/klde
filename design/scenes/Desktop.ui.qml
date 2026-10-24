// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

DesktopForm {
    MockApplications {
        id: apps
    }
    applications: apps
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
