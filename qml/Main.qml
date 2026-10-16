// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    objectName: "shellWindow"
    width: Tokens.previewWidth
    height: Tokens.previewHeight
    minimumWidth: Tokens.previewMinimumWidth
    minimumHeight: Tokens.previewMinimumHeight
    visible: true
    title: qsTr("KLDE Shell — Foundation")
    color: Tokens.background

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - Tokens.space32 * 2
        spacing: Tokens.space16

        Label {
            Layout.fillWidth: true
            text: "KLDE"
            font: Tokens.display
            color: Tokens.textPrimary
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            objectName: "statusLabel"
            Layout.fillWidth: true
            text: qsTr("Shell foundation · Phase 0")
            font: Tokens.title
            color: Tokens.textPrimary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Label {
            Layout.fillWidth: true
            text: qsTr("The desktop prototype begins after the first green CircleCI build.")
            font: Tokens.body
            color: Tokens.textSecondary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
