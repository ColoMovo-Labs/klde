// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "trayPopup"
    width: Math.min(Tokens.panelWidth, parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    height: column.implicitHeight + padding * 2
    contentItem: ColumnLayout {
        id: column
        spacing: Tokens.space12
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: I18n.t("tray.title")
                font: Tokens.label
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            IconButton {
                iconName: "close"
                text: I18n.t("tray.close")
                onClicked: root.close()
            }
        }
        Flow {
            Layout.fillWidth: true
            spacing: Tokens.space8
            Repeater {
                model: Shell.tray.items
                delegate: IconButton {
                    id: itemButton
                    required property var modelData
                    iconName: modelData.icon
                    text: modelData.title
                    ToolTip.visible: hovered
                    ToolTip.text: text
                    onClicked: {
                        const point = mapToGlobal(width / 2, height / 2);
                        Shell.tray.activate(modelData.id, Math.round(point.x), Math.round(point.y));
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            const point = itemButton.mapToGlobal(mouse.x, mouse.y);
                            if (mouse.button === Qt.RightButton)
                                Shell.tray.contextMenu(itemButton.modelData.id, Math.round(point.x), Math.round(point.y));
                            else
                                Shell.tray.activate(itemButton.modelData.id, Math.round(point.x), Math.round(point.y), true);
                        }
                    }
                }
            }
        }
        Label {
            visible: Shell.tray.items.length === 0
            text: I18n.t("tray.empty")
            font: Tokens.body
            color: Tokens.textSecondary
        }
    }
}
