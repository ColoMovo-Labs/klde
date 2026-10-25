// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import KLDE.Backends

RibbonForm {
    id: root
    showSamples: false
    signal action(string moduleId)
    leftWidth: left.naturalWidth
    rightWidth: right.naturalWidth
    centerWidth: center.width
    centerHeight: center.height
    property Item backdropSource: null
    property string islandState: "idle"
    visible: Shell.ribbon.enabled
    readonly property int degradation: stacked ? 3 : width < Tokens.ribbonFoldThreshold ? 2 : width < Tokens.ribbonCondenseThreshold ? 1 : 0
    implicitHeight: visible ? Math.max(center.height, leftHost.y + left.height, rightHost.y + right.height) : 0
    StatusRibbonSection {
        id: left
        parent: root.leftHost
        objectName: "ribbonLeft"
        degradation: root.degradation
        section: 0
        backdropSource: root.backdropSource
        width: Math.min(naturalWidth, root.sideWidth)
        y: 0
        height: implicitHeight
        onAction: moduleId => root.action(moduleId)
    }
    SystemIsland {
        id: center
        parent: root.centerHost
        objectName: "ribbonCenter"
        stateName: root.islandState
        sizeMode: root.degradation >= 2 ? "compact" : "standard"
        x: 0
        y: 0
        onClicked: root.action("time")
    }
    StatusRibbonSection {
        id: right
        parent: root.rightHost
        objectName: "ribbonRight"
        degradation: root.degradation
        section: 2
        backdropSource: root.backdropSource
        x: 0
        y: 0
        width: Math.min(naturalWidth, root.sideWidth)
        height: implicitHeight
        onAction: moduleId => root.action(moduleId)
    }
    Connections {
        target: root.leftHost
        function onXChanged(): void {
            Qt.callLater(left.refreshBackdrops);
        }
        function onYChanged(): void {
            Qt.callLater(left.refreshBackdrops);
        }
    }
    Connections {
        target: root.rightHost
        function onXChanged(): void {
            Qt.callLater(right.refreshBackdrops);
        }
        function onYChanged(): void {
            Qt.callLater(right.refreshBackdrops);
        }
    }
    GeometryDebugOverlay {
        anchors.fill: parent
        debugEnabled: Tokens.debugGeometry
        targetItems: [center, left, right]
        contentItems: [center.debugContentItem]
        textItems: [center.debugTextItem]
    }
}
