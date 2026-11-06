// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    heading: I18n.t("wallpaper.lock-preview")
    subtitle: I18n.t("wallpaper.lock-disclosure")
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Tokens.settingsWidth * 0.65
        radius: Tokens.radiusXL
        clip: true
        LockLandscape {
            anchors.fill: parent
            readonly property string choice: Shell.state.snapshot.appearance.wallpaper
            readonly property string stem: choice === "snow" ? Tokens.darkMode ? "first-night" : "first-light" : choice + (Tokens.darkMode ? "-night" : "")
            wallpaperSource: "qrc:/assets/wallpapers/" + stem + ".svg"
            foregroundSource: "qrc:/assets/wallpapers/snow-mountains" + (Tokens.darkMode ? "-night" : "") + ".svg"
            clockFontSource: "qrc:/assets/fonts/rubik/Rubik[wght].ttf"
            depthEnabled: choice === "snow"
            timeText: Shell.time.reading.timeText
            dateText: I18n.date(Shell.time.reading.dateTime, false)
            clockColor: Tokens.darkMode ? Tokens.primary : "#173b61"
            dateColor: Tokens.textPrimary
            transparencyEnabled: Tokens.transparencyEnabled
            blurEnabled: Shell.scenes.current.visual.blurEnabled
            blurQuality: Shell.scenes.current.visual.blurQuality
        }
    }
    Label {
        text: I18n.t(Shell.wallpaperEffects.state.cacheValid && Shell.wallpaperEffects.state.lockLinked ? "wallpaper.cache.ready" : "wallpaper.lock-fallback")
        font: Tokens.body
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
