// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    signal customizeRequested
    spacing: Tokens.space8
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Tokens.sceneCardHeight
        radius: Tokens.radiusXL
        color: Tokens.primaryContainer
        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.space16
            spacing: Tokens.space12
            Rectangle {
                Layout.preferredWidth: Tokens.dockItem
                Layout.preferredHeight: Tokens.dockItem
                radius: Tokens.radiusPill
                color: Tokens.surfaceElevated
                Icon {
                    anchors.centerIn: parent
                    name: Shell.scenes.current.icon
                    width: Tokens.iconM
                    height: Tokens.iconM
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.space4
                Label {
                    text: Shell.scenes.current.name
                    font: Tokens.title
                    color: Tokens.textPrimary
                }
                Label {
                    text: Shell.scenes.current.description
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font: Tokens.caption
                    color: Tokens.textSecondary
                }
                Label {
                    text: Shell.scenes.current.customized ? qsTr("Customized · session only") : qsTr("Default scene · mock system policy")
                    font: Tokens.caption
                    color: Tokens.textSecondary
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space4
        Repeater {
            model: Shell.scenes.scenes
            delegate: Button {
                id: sceneButton
                required property var modelData
                readonly property bool selected: modelData.id === Shell.scenes.activeId
                Layout.fillWidth: true
                text: (selected ? "✓ " : "") + modelData.name
                font: Tokens.caption
                Accessible.name: modelData.name + (selected ? qsTr(", selected") : "")
                onClicked: Shell.scenes.select(modelData.id)
                background: Rectangle {
                    radius: Tokens.radiusPill
                    color: sceneButton.selected ? Tokens.primaryContainer : Tokens.surfaceContainer
                    border.width: sceneButton.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                }
            }
        }
    }
    Button {
        Layout.fillWidth: true
        text: qsTr("Customize scene & appearance…")
        font: Tokens.label
        onClicked: root.customizeRequested()
    }
}
