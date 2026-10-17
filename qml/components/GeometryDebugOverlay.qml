// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

// Development-only geometry inspection. It is opt-in through Tokens.debugGeometry
// and is never visible in normal previews.
Item {
    id: root
    property bool enabled: false
    property var targetItems: []
    property var contentItems: []
    property var textItems: []
    property var iconItems: []
    visible: enabled
    z: 10000
    clip: false

    Repeater {
        model: root.targetItems
        delegate: Item {
            required property var modelData
            readonly property Item targetItem: modelData
            readonly property var targetPosition: targetItem ? targetItem.mapToItem(root, 0, 0) : Qt.point(0, 0)
            x: targetPosition.x
            y: targetPosition.y
            width: targetItem ? targetItem.width : 0
            height: targetItem ? targetItem.height : 0
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: Tokens.primary
            }
            Rectangle {
                x: parent.width / 2
                y: 0
                width: 1
                height: parent.height
                color: Tokens.primary
                opacity: 0.8
            }
            Rectangle {
                x: 0
                y: parent.height / 2
                width: parent.width
                height: 1
                color: Tokens.primary
                opacity: 0.8
            }
            Label {
                text: targetItem ? targetItem.objectName || "target" : "target"
                x: 4
                y: 2
                color: Tokens.primary
                font: Tokens.caption
                background: Rectangle {
                    color: Qt.rgba(Tokens.background.r, Tokens.background.g, Tokens.background.b, 0.86)
                    radius: Tokens.radiusXS
                }
            }
        }
    }

    Repeater {
        model: root.contentItems
        delegate: Rectangle {
            required property var modelData
            readonly property Item contentItem: modelData
            readonly property var contentPosition: contentItem ? contentItem.mapToItem(root, 0, 0) : Qt.point(0, 0)
            x: contentPosition.x
            y: contentPosition.y
            width: contentItem ? contentItem.width : 0
            height: contentItem ? contentItem.height : 0
            color: "transparent"
            border.width: 1
            border.color: Tokens.secondary
        }
    }

    Repeater {
        model: root.textItems
        delegate: Item {
            required property var modelData
            readonly property Item textItem: modelData
            readonly property var textPosition: textItem ? textItem.mapToItem(root, 0, 0) : Qt.point(0, 0)
            x: textPosition.x
            y: textPosition.y
            width: textItem ? textItem.width : 0
            height: textItem ? textItem.height : 0
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: Tokens.tertiary
            }
            Rectangle {
                x: 0
                y: textItem ? textItem.baselineOffset : 0
                width: parent.width
                height: 1
                color: Tokens.tertiary
            }
        }
    }

    Repeater {
        model: root.iconItems
        delegate: Rectangle {
            required property var modelData
            readonly property Item iconItem: modelData
            readonly property var iconPosition: iconItem ? iconItem.mapToItem(root, 0, 0) : Qt.point(0, 0)
            x: iconPosition.x
            y: iconPosition.y
            width: iconItem ? iconItem.width : 0
            height: iconItem ? iconItem.height : 0
            color: "transparent"
            border.width: 1
            border.color: Tokens.error
        }
    }
}
