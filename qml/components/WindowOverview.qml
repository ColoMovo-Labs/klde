// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import KLDE.Backends

// Cutefish-inspired task overview: presentation stays in the shell while
// activation and closing remain asynchronous WindowManagerBackend operations.
ShellPopup {
    id: root
    objectName: "windowOverview"
    modal: true
    dim: false
    focus: true
    width: Math.min(780, parent ? parent.width - Tokens.space32 : 780)
    height: Math.min(560, parent ? parent.height - Tokens.space32 : 560)
    property int currentIndex: 0
    readonly property var visibleWindows: Shell.windowManager.windows.filter(window => {
        const active = Shell.windowManager.activeWorkspace;
        return !window.minimized && (window.onAllWorkspaces || window.workspaceId === active || (window.workspaceIds || []).indexOf(active) >= 0);
    })
    onOpened: {
        currentIndex = Math.max(0, Math.min(currentIndex, visibleWindows.length - 1));
        overviewGrid.forceActiveFocus();
    }
    function activate(index: int): void {
        const window = visibleWindows[index];
        if (window && Shell.windowManager.activateWindow(window.id))
            root.close();
    }
    function closeWindow(index: int): void {
        const window = visibleWindows[index];
        if (window && window.closeable)
            Shell.windowManager.closeWindow(window.id);
    }
    contentItem: ColumnLayout {
        spacing: Tokens.space16
        PanelHeaderForm {
            Layout.fillWidth: true
            title: I18n.t("lab.module.overview")
            subtitle: Shell.windowManager.capabilities.mock ? I18n.t("settings.about.preview") : I18n.t("backend.window-manager.application")
        }
        Label {
            Layout.fillWidth: true
            visible: root.visibleWindows.length === 0
            text: I18n.t("shell.overview.empty")
            color: Tokens.textSecondary
            font: Tokens.body
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredHeight: Tokens.space64 * 2
        }
        GridView {
            id: overviewGrid
            objectName: "windowOverviewGrid"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.visibleWindows.length > 0
            model: root.visibleWindows
            cellWidth: Math.max(220, Math.floor(width / 2))
            cellHeight: 152
            clip: true
            keyNavigationWraps: false
            currentIndex: root.currentIndex
            onCurrentIndexChanged: root.currentIndex = currentIndex
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                    root.currentIndex = Math.max(0, root.currentIndex - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                    root.currentIndex = Math.min(root.visibleWindows.length - 1, root.currentIndex + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate(root.currentIndex);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete) {
                    root.closeWindow(root.currentIndex);
                    event.accepted = true;
                }
            }
            delegate: Button {
                id: card
                required property var modelData
                required property int index
                width: overviewGrid.cellWidth - Tokens.space12
                height: overviewGrid.cellHeight - Tokens.space12
                property bool selected: index === root.currentIndex
                Accessible.name: (modelData.title || modelData.applicationId || I18n.t("backend.window-manager.application")) + (selected ? " · " + I18n.t("common.selected") : "")
                hoverEnabled: true
                onClicked: root.activate(index)
                onPressAndHold: root.closeWindow(index)
                contentItem: ColumnLayout {
                    spacing: Tokens.space8
                    Label {
                        Layout.fillWidth: true
                        text: modelData.title || modelData.applicationId || I18n.t("backend.window-manager.application")
                        color: card.selected ? Tokens.textOnPrimary : Tokens.textPrimary
                        font: Tokens.title
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.applicationId || I18n.t("backend.window-manager.application")
                        color: card.selected ? Tokens.textOnPrimary : Tokens.textSecondary
                        font: Tokens.caption
                        elide: Text.ElideRight
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.closeable ? I18n.t("shell.overview.close-hint") : ""
                        visible: text.length > 0
                        color: card.selected ? Tokens.textOnPrimary : Tokens.textSecondary
                        font: Tokens.caption
                    }
                }
                background: Rectangle {
                    radius: card.selected ? Tokens.radiusXL : Tokens.radiusL
                    color: card.selected ? Tokens.primary : card.hovered ? Tokens.surfaceContainerHigh : Tokens.surfaceContainer
                    border.width: card.visualFocus || card.selected ? Tokens.space2 : Tokens.space1
                    border.color: card.selected || card.visualFocus ? Tokens.primary : Tokens.outline
                }
            }
        }
    }
}
