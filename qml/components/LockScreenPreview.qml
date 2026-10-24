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
        WallpaperLayers {
            anchors.fill: parent
            lockPreview: true
        }
        Column {
            anchors.centerIn: parent
            spacing: Tokens.space12
            DisplayClock {
                pixelSize: Tokens.workingClockSize * 1.7
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.date(Shell.time.reading.dateTime, false)
                color: Tokens.textPrimary
                font: Tokens.label
            }
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
