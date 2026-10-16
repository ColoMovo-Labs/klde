// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Item {
    id: root
    default property alias contentData: content.data
    property real padding: Tokens.space16
    property real cornerRadius: Tokens.radiusXL
    property color tone: Tokens.surfaceElevated

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Tokens.elevationLow
        anchors.bottomMargin: -Tokens.elevationLow
        radius: root.cornerRadius
        color: Tokens.shadow
        opacity: Tokens.shadowsEnabled ? Tokens.shadowOpacity : 0
    }
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, Tokens.transparencyEnabled ? Tokens.surfaceOpacityHigh : 1)
        border.width: Tokens.space1
        border.color: Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
    }
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
