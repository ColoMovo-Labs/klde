// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Image {
    id: root
    property string name: "klde"
    property bool lightInk: Tokens.darkMode
    width: Tokens.iconM
    height: Tokens.iconM
    source: root.name === "klde" ? Assets.root + "branding/owode-logo.png" : root.name.startsWith("image://applications/") ? root.name : Assets.root + "icons/" + root.name + (root.lightInk ? "-light" : "") + ".svg"
    asynchronous: false
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
}
