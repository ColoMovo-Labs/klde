// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import KLDE.Backends

// One bounded pipeline per tiered surface: a non-live capture of the owned
// wallpaper, a public MultiEffect blur, then material.frag for coverage,
// refraction, tint and rim. Nothing here requests frames on its own.
Item {
    id: root
    required property Item sourceItem
    required property var spec
    property real cornerRadius: Tokens.radiusXL
    property int revision: 0
    property real press: 0
    readonly property real qualityScale: Shell.blur.quality === BlurBackend.Low ? 0.5 : Shell.blur.quality === BlurBackend.High ? 1.5 : 1.0
    readonly property real captureScale: Math.min(1, spec.captureScale * qualityScale)
    property point sampleOrigin: Qt.point(0, 0)
    function refresh(): void {
        if (!sourceItem)
            return;
        sampleOrigin = mapToItem(sourceItem, 0, 0);
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
        onSourceRectChanged: scheduleUpdate()
        onTextureSizeChanged: scheduleUpdate()
    }
    MultiEffect {
        id: blurred
        anchors.fill: parent
        source: capture
        autoPaddingEnabled: false
        blurEnabled: root.spec.blur > 0
        blurMax: root.spec.blurMax
        blur: root.spec.blur
        visible: false
        layer.enabled: true
    }
    ShaderEffect {
        anchors.fill: parent
        property Item source: blurred
        property size size: Qt.size(width, height)
        property real radius: root.cornerRadius
        property real refraction: root.spec.refraction
        property real edge: root.spec.edge
        property real dispersion: root.spec.dispersion
        property color tint: root.spec.tint
        property real tintOpacity: root.spec.tintOpacity
        property real saturation: root.spec.saturation
        property real grain: root.spec.grain
        property real rim: root.spec.rim
        property real specular: root.spec.specular
        property point lightDir: Tokens.materialLight
        property real press: root.press
        fragmentShader: "qrc:/shaders/material.frag.qsb"
    }
}
