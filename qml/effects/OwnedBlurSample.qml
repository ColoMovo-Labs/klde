// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import KLDE.Backends

Item {
    id: root
    property int revision: 0
    readonly property bool gpuActive: Shell.blur.ownedContentAvailable && Shell.blur.renderingAllowed && Shell.blur.quality !== BlurBackend.Off && Shell.blur.strategyFor(true) === BlurBackend.OwnedContentGpu
    implicitWidth: Tokens.blurSampleWidth
    implicitHeight: Tokens.blurSampleHeight
    clip: true
    Image {
        id: ownedContent
        anchors.fill: parent
        source: "qrc:/assets/wallpapers/first-light.svg"
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
    }
    Loader {
        anchors.fill: parent
        active: root.visible && root.gpuActive
        sourceComponent: Component {
            Item {
                ShaderEffectSource {
                    id: frozenSource
                    anchors.fill: parent
                    sourceItem: ownedContent
                    hideSource: true
                    live: false
                    visible: false
                    textureSize: Qt.size(Math.max(1, root.width / 2), Math.max(1, root.height / 2))
                    Component.onCompleted: scheduleUpdate()
                    onTextureSizeChanged: scheduleUpdate()
                }
                MultiEffect {
                    anchors.fill: parent
                    source: frozenSource
                    blurEnabled: true
                    blurMax: Tokens.blurHigh
                    blur: Shell.blur.quality / BlurBackend.High
                }
                Connections {
                    target: root
                    function onRevisionChanged(): void {
                        frozenSource.scheduleUpdate();
                    }
                }
            }
        }
    }
}
