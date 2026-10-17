// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import KLDE.Backends

Item {
    id: root
    signal action(string moduleId)
    visible: Shell.ribbon.enabled
    implicitHeight: visible ? Math.max(left.height, center.height, right.height) : 0
    readonly property real gap: Tokens.space16
    StatusRibbonSection {
        id: left
        section: 0
        width: Math.max(Tokens.controlHeight, Math.min(naturalWidth, parent.width * Tokens.ribbonLeftShare))
        height: childrenRect.height
        onAction: moduleId => root.action(moduleId)
    }
    StatusRibbonSection {
        id: center
        objectName: "ribbonCenter"
        section: 1
        width: Math.max(Tokens.controlHeight, Math.min(naturalWidth, parent.width * Tokens.ribbonCenterShare))
        x: (parent.width - width) / 2
        height: childrenRect.height
        onAction: moduleId => root.action(moduleId)
    }
    StatusRibbonSection {
        id: right
        section: 2
        x: center.x + center.width + root.gap
        width: parent.width - x
        height: childrenRect.height
        onAction: moduleId => root.action(moduleId)
    }
}
