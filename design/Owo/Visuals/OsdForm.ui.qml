// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.panelWidth
    height: Tokens.dockHeight
    property alias text: message.text
    SurfaceForm {
        anchors.fill: parent
    }
    Text {
        id: message
        anchors.fill: parent
        anchors.margins: Tokens.space16
        text: "音量 77%"
        color: Tokens.textPrimary
        font: Tokens.label
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
}
