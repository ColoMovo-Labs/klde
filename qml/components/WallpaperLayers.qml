// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import KLDE.Backends

Item {
    id: root
    property bool foregroundOnly: false
    property bool lockPreview: false
    readonly property var effects: Shell.wallpaperEffects.state
    readonly property string choice: Shell.state.snapshot.appearance.wallpaper
    readonly property string original: "qrc:/assets/wallpapers/" + (choice === "snow" ? Tokens.darkMode ? "first-night" : "first-light" : choice + (Tokens.darkMode ? "-night" : "")) + ".svg"
    function nightAsset(source: string): string {
        return Tokens.darkMode && source.length > 0 ? source.replace(".svg", "-night.svg") : source;
    }
    Image {
        anchors.fill: parent
        visible: !root.foregroundOnly
        source: visible ? root.original : ""
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
    }
    Image {
        anchors.fill: parent
        visible: !root.foregroundOnly && (root.lockPreview ? root.effects.lockAsset.length > 0 : root.effects.effectiveMode === "soft-blur")
        source: visible ? root.nightAsset(root.lockPreview ? root.effects.lockAsset : root.effects.softAsset) : ""
        opacity: (root.lockPreview ? root.effects.lockBlurStrength : root.effects.blurStrength) / 3
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
    }
    Image {
        anchors.fill: parent
        visible: root.foregroundOnly && root.effects.effectiveMode === "depth"
        source: visible ? root.nightAsset(root.effects.foregroundAsset) : ""
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
        scale: 1 + [0, Tokens.depthLow, Tokens.depthMedium, Tokens.depthHigh][root.effects.depthTier]
    }
    Rectangle {
        anchors.fill: parent
        visible: !root.foregroundOnly
        color: Tokens.background
        opacity: root.lockPreview && !Tokens.darkMode ? Tokens.wallpaperDim : 0
    }
}
