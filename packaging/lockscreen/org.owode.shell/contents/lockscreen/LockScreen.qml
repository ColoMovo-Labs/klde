// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// The stable entry point deliberately imports no optional presentation modules.
// Both appearances use the unchanged KDE Greeter and its system authenticator.
Item {
    id: root
    property bool locked: false
    property bool capsLockOn: false
    signal unlockRequested
    function returnToLogin(): void {
        if (appearance.item)
            appearance.item.returnToLogin();
    }
    Loader {
        id: appearance
        anchors.fill: parent
        source: "OwoLockScreen.qml"
        onStatusChanged: {
            if (status === Loader.Error && source.toString().endsWith("OwoLockScreen.qml")) {
                console.warn("owoDE: custom locker appearance failed; using KDE Greeter");
                source = "KdeLockScreen.qml";
            }
        }
        onLoaded: {
            item.locked = Qt.binding(() => root.locked);
            item.capsLockOn = Qt.binding(() => root.capsLockOn);
            root.returnToLogin();
        }
    }
}
