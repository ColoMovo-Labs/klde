// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.previewWidth
    height: Tokens.previewHeight
    property url wallpaper: Assets.root + "wallpapers/first-light.svg"
    property alias dim: dimLayer.opacity
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: root.wallpaper
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle {
        id: dimLayer
        anchors.fill: parent
        color: Tokens.background
        opacity: 0
    }
}
