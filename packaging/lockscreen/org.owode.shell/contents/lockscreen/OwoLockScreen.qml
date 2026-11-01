// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import org.kde.kirigami 2.20 as Kirigami

// Presentation only. The unchanged, attributed KDE Greeter below talks to
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
    Image {
        anchors.fill: parent
        source: "../assets/snow.svg"
        fillMode: Image.PreserveAspectCrop
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(theme.space32, parent.height * 0.12)
        spacing: theme.space8
        Label {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            color: theme.textPrimaryLight
            font.pixelSize: theme.displaySize * 2
            font.weight: Font.DemiBold
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "owoDE"
            color: theme.primaryLight
            font.pixelSize: theme.titleSize
        }
    }
    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
    }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - theme.space32 * 2, greeter.implicitWidth + theme.space32 * 2)
        height: greeter.implicitHeight + theme.space32 * 2
        radius: theme.radiusXL
        color: Kirigami.Theme.backgroundColor
        visible: root.locked
        Greeter {
            id: greeter
            anchors.centerIn: parent
            switchUserEnabled: false
        }
    }
    function returnToLogin(): void {
        greeter.resetFocus();
    }
}
