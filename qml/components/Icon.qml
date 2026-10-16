// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Image {
    property string name: "klde"
    implicitWidth: Tokens.iconM
    implicitHeight: Tokens.iconM
    source: "qrc:/assets/icons/" + name + ".svg"
    sourceSize: Qt.size(width, height)
    fillMode: Image.PreserveAspectFit
    asynchronous: false
}
