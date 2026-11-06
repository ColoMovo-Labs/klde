// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Minimal system-palette presentation of the attributed KDE Greeter.
// No optional session-switching plugin, wallpaper, tokens or custom effects.
Rectangle {
    id: root
    property bool locked: false
    property alias capsLockOn: greeter.capsLockOn
    color: palette.window
    SystemPalette {
        id: palette
    }
    Greeter {
        id: greeter
        anchors.centerIn: parent
        visible: root.locked
        switchUserEnabled: false
    }
    function returnToLogin(): void {
        greeter.resetFocus();
    }
}
