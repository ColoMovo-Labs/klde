// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Effects
import KLDE.Backends

Item {
    id: root
    default property alias contentData: content.data
    property bool decorationVisible: true
    property real padding: Tokens.space16
    property real cornerRadius: Tokens.radiusXL
    property color tone: Tokens.surfaceElevated
    property Item backdropSource: null
    property int backdropRevision: 0
    // "classic" keeps the 0.1 visual freeze. "mica", "acrylic" and "glass" are
    // the fusion study tiers described in docs/design/material-motion.md.
    property string material: "classic"
    // 0..1 press depth; only Glass reacts by deepening refraction and sheen.
    property real pressAmount: 0
    readonly property bool tiered: material !== "classic"
    readonly property var spec: tiered ? Tokens.materials[material] : ({})
    readonly property color fill: tiered ? spec.tint : tone
    readonly property bool effectsAvailable: Shell.blur.ownedContentAvailable && Shell.blur.renderingAllowed
    readonly property bool hasBlur: backdropSource !== null && Tokens.transparencyEnabled && effectsAvailable && Shell.blur.quality !== BlurBackend.Off
    readonly property bool materialActive: tiered && hasBlur

    function refreshCapture(): void {
        backdropRevision += 1;
    }
    onXChanged: Qt.callLater(refreshCapture)
    onYChanged: Qt.callLater(refreshCapture)
    Connections {
        target: Tokens
        function onDarkModeChanged(): void {
            Qt.callLater(root.refreshCapture);
        }
        function onWallpaperChoiceChanged(): void {
            Qt.callLater(root.refreshCapture);
        }
    }

    Loader {
        anchors.fill: parent
        active: root.visible && root.decorationVisible && root.hasBlur && !root.tiered
        sourceComponent: Component {
            OwnedBackdrop {
                sourceItem: root.backdropSource
                cornerRadius: root.cornerRadius
                revision: root.backdropRevision
            }
        }
    }
    Rectangle {
        visible: root.decorationVisible && (!root.tiered || !root.effectsAvailable)
        anchors.fill: parent
        anchors.topMargin: Tokens.elevationLow
        anchors.bottomMargin: -Tokens.elevationLow
        radius: root.cornerRadius
        color: Tokens.shadow
        opacity: Tokens.shadowsEnabled ? Tokens.shadowOpacity * (Tokens.shadowLevel === 0 ? 0.6 : Tokens.shadowLevel === 2 ? 1.4 : 1) : 0
    }
    // Tiered surfaces cast a soft, blurred shadow: one ambient layer for Glass,
    // a deeper key shadow for transient Acrylic. Mica sits flat on the wallpaper.
    Loader {
        anchors.fill: parent
        active: root.visible && root.decorationVisible && root.tiered && root.effectsAvailable && Tokens.shadowsEnabled && root.spec.shadow > 0
        sourceComponent: Component {
            Item {
                Rectangle {
                    id: shadowShape
                    anchors.fill: parent
                    radius: root.cornerRadius
                    color: root.fill
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: shadowShape
                    shadowEnabled: true
                    shadowColor: Tokens.shadow
                    shadowOpacity: Tokens.shadowOpacity * (root.spec.shadow === 2 ? 1.6 : 1.1)
                    shadowBlur: 1.0
                    blurMax: root.spec.shadow === 2 ? 40 : 24
                    shadowVerticalOffset: root.spec.shadow === 2 ? Tokens.elevationHigh / 1.5 : Tokens.elevationMedium / 1.5
                }
            }
        }
    }
    Loader {
        anchors.fill: parent
        active: root.visible && root.decorationVisible && root.materialActive
        sourceComponent: Component {
            MaterialBackdrop {
                sourceItem: root.backdropSource
                spec: root.spec
                cornerRadius: root.cornerRadius
                revision: root.backdropRevision
                press: root.pressAmount
            }
        }
    }
    SurfaceForm {
        visible: root.decorationVisible && !root.materialActive
        anchors.fill: parent
        cornerRadius: root.cornerRadius
        tone: root.fill
        fillOpacity: root.hasBlur ? Tokens.frostedSurfaceOpacity : 1
        shadowOpacity: 0
    }
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
