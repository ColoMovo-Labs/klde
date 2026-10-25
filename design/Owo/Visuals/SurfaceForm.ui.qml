// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.panelWidth
    height: Tokens.widgetSize
    property real cornerRadius: Tokens.radiusXL
    property color tone: Tokens.surfaceElevated
    property color edge: Tokens.surfaceEdge
    property real fillOpacity: 1
    property real shadowOpacity: Tokens.shadowsEnabled ? Tokens.shadowOpacity : 0
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Tokens.elevationLow
        anchors.bottomMargin: -Tokens.elevationLow
        radius: root.cornerRadius
        color: Tokens.shadow
        opacity: root.shadowOpacity
    }
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.tone
        opacity: root.fillOpacity
        border.width: Tokens.space1
        border.color: root.edge
    }
}
