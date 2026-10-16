// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Item {
    id: root
    property string name: "klde"
    property bool lightInk: Tokens.darkMode
    implicitWidth: Tokens.iconM
    implicitHeight: Tokens.iconM
    Image {
        anchors.fill: parent
        source: "qrc:/assets/icons/" + root.name + (root.lightInk ? "-light" : "") + ".svg"
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectFit
        asynchronous: false
    }
}
