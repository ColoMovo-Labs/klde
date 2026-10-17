// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import KLDE.Backends

Item {
    id: root
    signal action(string moduleId)
    visible: Shell.ribbon.enabled
    readonly property bool stacked: width < Tokens.ribbonStackThreshold
    readonly property real sideWidth: stacked ? (width - Tokens.ribbonGroupGap) / 2 : center.x - Tokens.ribbonGroupGap
    implicitHeight: visible ? Math.max(center.height, left.y + left.height, right.y + right.height) : 0
    StatusRibbonSection {
        id: left
        section: 0
        width: root.sideWidth
        y: root.stacked ? center.height + Tokens.ribbonGroupGap : 0
        height: implicitHeight
        onAction: moduleId => root.action(moduleId)
    }
    TemporalCapsule {
        id: center
        objectName: "ribbonCenter"
        x: (parent.width - width) / 2
        onClicked: root.action("time")
    }
    StatusRibbonSection {
        id: right
        section: 2
        x: root.stacked ? parent.width - width : center.x + center.width + Tokens.ribbonGroupGap
        y: left.y
        width: root.sideWidth
        height: implicitHeight
        onAction: moduleId => root.action(moduleId)
    }
}
