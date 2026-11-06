// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtCore
import org.kde.kirigami 2.20 as Kirigami

// Presentation only. The attributed KDE Greeter below talks to
// KScreenLocker's authenticator. This file never handles a password or unlocks.
Item {
    id: root
    property bool locked: false
    property alias capsLockOn: greeter.capsLockOn
    signal unlockRequested
    ThemeValues {
        id: theme
        visible: false
    }
    property date currentTime: new Date()
    Settings {
        id: appearanceSettings
        location: "file://" + StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/owode/lockscreen.conf"
        category: "Appearance"
        property bool transparencyEnabled: true
        property bool blurEnabled: true
        property int blurQuality: 2
        property bool darkMode: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    }
    readonly property bool darkAppearance: appearanceSettings.darkMode
    LockLandscape {
        anchors.fill: parent
        wallpaperSource: root.darkAppearance ? "../assets/first-night.svg" : "../assets/snow.svg"
        foregroundSource: root.darkAppearance ? "../assets/snow-mountains-night.svg" : "../assets/snow-mountains.svg"
        clockFontSource: "../assets/Rubik[wght].ttf"
        timeText: Qt.formatTime(root.currentTime, "hh:mm")
        dateText: Qt.formatDate(root.currentTime, Qt.locale().dateFormat(Locale.LongFormat))
        clockColor: root.darkAppearance ? theme.primaryDark : "#173b61"
        dateColor: root.darkAppearance ? theme.textPrimaryDark : theme.textPrimaryLight
        transparencyEnabled: appearanceSettings.transparencyEnabled
        blurEnabled: appearanceSettings.blurEnabled
        blurQuality: appearanceSettings.blurQuality
    }
    Timer {
        interval: 60000 - (Date.now() % 60000)
        repeat: true
        running: root.visible
        // Update only on a minute boundary, including after waking from sleep.
        onTriggered: {
            root.currentTime = new Date();
            interval = 60000 - (Date.now() % 60000);
        }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(theme.space8, Math.min(parent.height * 0.62 - height / 2, parent.height - height - theme.space16))
        width: Math.min(parent.width - theme.space32 * 2, greeter.implicitWidth + theme.space32 * 2)
        height: greeter.implicitHeight + theme.space32 * 2
        radius: theme.radiusXL
        color: Kirigami.Theme.backgroundColor
        visible: root.locked
        border.width: 1
        border.color: Kirigami.Theme.alternateBackgroundColor
        Greeter {
            id: greeter
            anchors.centerIn: parent
            switchUserEnabled: false
        }
    }
    function returnToLogin(): void {
        if (root.locked)
            greeter.resetFocus();
    }
}
