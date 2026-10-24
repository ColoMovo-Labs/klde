// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Image {
    id: root
    property string name: "klde"
    property bool lightInk: Tokens.darkMode
    width: Tokens.iconM
    height: Tokens.iconM
    source: Assets.root + "icons/" + root.name + (root.lightInk ? "-light" : "") + ".svg"
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
}
