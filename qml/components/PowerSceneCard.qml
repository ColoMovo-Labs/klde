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
        color: Tokens.primary
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
                    text: I18n.s(Shell.scenes.current.name)
                    font: Tokens.title
                    color: Tokens.textOnPrimary
                }
                Label {
                    text: I18n.s(Shell.scenes.current.description)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font: Tokens.caption
                    color: Tokens.textOnPrimary
                }
                Label {
                    text: Shell.scenes.current.customized ? I18n.t("shell.scene.customized") : I18n.t("shell.scene.default")
                    font: Tokens.caption
                    color: Tokens.textOnPrimary
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
                text: (selected ? "✓ " : "") + I18n.s(modelData.name)
                font: Tokens.caption
                Accessible.name: I18n.s(modelData.name) + (selected ? I18n.t("common.selected") : "")
                onClicked: Shell.scenes.select(modelData.id)
                contentItem: Label {
                    text: sceneButton.text
                    font: sceneButton.font
                    color: sceneButton.selected ? Tokens.textOnPrimary : Tokens.textPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: Tokens.radiusPill
                    color: sceneButton.selected ? Tokens.primary : Tokens.surfaceContainer
                    border.width: sceneButton.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                }
            }
        }
    }
    ActionButton {
        Layout.fillWidth: true
        text: I18n.t("shell.scene.customize")
        font: Tokens.label
        onClicked: root.customizeRequested()
    }
}
