// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import KLDE.Backends

Item {
    id: root
    required property Item sourceItem
    property real cornerRadius: Tokens.radiusXL
    property int revision: 0
    readonly property real captureScale: Shell.blur.quality === BlurBackend.Low ? Tokens.blurScaleLow : Shell.blur.quality === BlurBackend.High ? Tokens.blurScaleHigh : Tokens.blurScaleMedium
    // Capture only a region of the preview's own wallpaper. Never another window.
    property point sampleOrigin: Qt.point(0, 0)
    function refresh(): void {
        if (!sourceItem)
            return;
        sampleOrigin = mapToItem(sourceItem, 0, 0);
        if (capture)
            capture.scheduleUpdate();
    }
    Component.onCompleted: Qt.callLater(refresh)
    onWidthChanged: Qt.callLater(refresh)
    onHeightChanged: Qt.callLater(refresh)
    onRevisionChanged: Qt.callLater(refresh)
    Connections {
        target: root.sourceItem
        function onWidthChanged(): void {
            Qt.callLater(root.refresh);
        }
        function onHeightChanged(): void {
            Qt.callLater(root.refresh);
        }
    }
    ShaderEffectSource {
        id: capture
        anchors.fill: parent
        sourceItem: root.sourceItem
        sourceRect: Qt.rect(root.sampleOrigin.x, root.sampleOrigin.y, root.width, root.height)
        textureSize: Qt.size(Math.min(Tokens.blurTextureLimit, Math.max(1, root.width * root.captureScale)), Math.min(Tokens.blurTextureLimit, Math.max(1, root.height * root.captureScale)))
        live: false
        visible: false
        Component.onCompleted: scheduleUpdate()
        onSourceRectChanged: scheduleUpdate()
        onTextureSizeChanged: scheduleUpdate()
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.cornerRadius
        color: "white"
        layer.enabled: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: capture
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: Tokens.blurHigh
        blur: 1.0
        maskEnabled: true
        maskSource: mask
    }
}
