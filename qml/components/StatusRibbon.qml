// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import KLDE.Backends

Item {
    id: root
    signal action(string moduleId)
    property string islandState: "idle"
    visible: Shell.ribbon.enabled
    readonly property bool stacked: width < Tokens.ribbonStackThreshold
    readonly property int degradation: stacked ? 3 : width < Tokens.ribbonFoldThreshold ? 2 : width < Tokens.ribbonCondenseThreshold ? 1 : 0
    readonly property real sideWidth: stacked ? (width - Tokens.ribbonGroupGap) / 2 : center.x - Tokens.ribbonGroupGap
    implicitHeight: visible ? Math.max(center.height, left.y + left.height, right.y + right.height) : 0
    StatusRibbonSection {
        id: left
        objectName: "ribbonLeft"
        degradation: root.degradation
        section: 0
        width: Math.min(naturalWidth, root.sideWidth)
        y: root.stacked ? Tokens.ribbonBandHeight + Tokens.ribbonGroupGap : 0
        height: implicitHeight
        onAction: moduleId => root.action(moduleId)
    }
    SystemIsland {
        id: center
        objectName: "ribbonCenter"
        stateName: root.islandState
        sizeMode: root.degradation >= 2 ? "compact" : "standard"
        x: (parent.width - width) / 2
        y: (Tokens.ribbonBandHeight - height) / 2
        onClicked: root.action("time")
    }
    StatusRibbonSection {
        id: right
        objectName: "ribbonRight"
        degradation: root.degradation
        section: 2
        x: parent.width - width
        y: left.y
        width: Math.min(naturalWidth, root.sideWidth)
        height: implicitHeight
        onAction: moduleId => root.action(moduleId)
    }
    GeometryDebugOverlay {
        anchors.fill: parent
        enabled: Tokens.debugGeometry
        targetItems: [center, left, right]
        contentItems: [center.debugContentItem]
        textItems: [center.debugTextItem]
    }
}
