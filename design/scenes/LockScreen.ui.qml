// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 1440
    height: 900
    LockLandscape {
        anchors.fill: parent
        wallpaperSource: Assets.root + "wallpapers/first-" + (Tokens.darkMode ? "night" : "light") + ".svg"
        foregroundSource: Assets.root + "wallpapers/snow-mountains" + (Tokens.darkMode ? "-night" : "") + ".svg"
        clockFontSource: Assets.root + "fonts/rubik/Rubik[wght].ttf"
        timeText: "08:30"
        dateText: "10月17日 周六 · Saturday, October 17"
        clockColor: Tokens.darkMode ? Tokens.primary : "#173b61"
        dateColor: Tokens.textPrimary
        transparencyEnabled: Tokens.transparencyEnabled
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
