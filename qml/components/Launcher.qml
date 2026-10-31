// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "launcher"
    modal: true
    dim: false
    transformOrigin: Item.Bottom
    property bool gridMode: true
    property int currentIndex: 0
    readonly property var applicationNames: ({
            files: I18n.s("Files"),
            web: I18n.s("Browser"),
            terminal: I18n.s("Terminal"),
            notes: I18n.s("Notes"),
            music: I18n.s("Music"),
            settings: I18n.s("Settings")
        })
    readonly property var applicationDescriptions: ({
            files: I18n.s("Your everyday places"),
            web: I18n.s("A little window to the world"),
            terminal: I18n.s("Make something happen"),
            notes: I18n.s("Keep a thought close"),
            music: I18n.s("Find your rhythm"),
            settings: I18n.s("Make this space yours")
        })
    width: Math.min(Math.max(Tokens.launcherWidth, integratedDock.implicitWidth + padding * 2), parent ? parent.width - Tokens.space32 : Tokens.launcherWidth)
    readonly property int gridColumns: Math.max(2, Math.floor((width - padding * 2) / Tokens.launcherGridMinimumCell))
    readonly property real resultsHeight: gridMode ? Math.max(1, Math.min(3, Math.ceil(Shell.search.count / gridColumns))) * Tokens.launcherGridCellHeight * Tokens.textScale : Math.max(1, Math.min(6, Shell.search.count)) * (Tokens.launcherRow * Tokens.textScale + Tokens.space4)
    height: Math.min(Math.min(resultsHeight, Tokens.launcherHeight) + Tokens.controlHeight + Tokens.dockHeight + padding * 2 + Tokens.space32 + Tokens.space1, parent ? parent.height - Tokens.space32 : Tokens.previewHeight)
    Behavior on height {
        NumberAnimation {
            duration: Tokens.springSpatial.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatial.curve
        }
    }
    onOpened: {
        if (!Shell.applications.preview)
            Shell.desktopApplications.refresh();
        Shell.search.query = "";
        currentIndex = 0;
        form.searchField.forceActiveFocus();
    }
    function activateApp(appId: string, index: int): void {
        if (appId === "settings") {
            close();
            settingsRequested();
        } else if (Shell.launch(appId)) {
            close();
        }
    }
    signal settingsRequested
    property string menuApplication: ""
    property bool menuPinned: false
    function requestApplicationMenu(appId: string): void {
        if (Shell.applications.preview)
            return;
        menuApplication = appId;
        menuPinned = Shell.applications.isPinned(appId);
        applicationMenu.popup();
    }
    Menu {
        id: applicationMenu
        objectName: "applicationContextMenu"
        MenuItem {
            text: root.menuPinned ? I18n.t("shell.launcher.unpin") : I18n.t("shell.launcher.pin")
            enabled: Shell.applications.canPin(root.menuApplication)
            onTriggered: Shell.applications.setPinned(root.menuApplication, !root.menuPinned)
        }
    }
    function moveSelection(delta: int): void {
        currentIndex = Math.max(0, Math.min(Shell.search.count - 1, currentIndex + delta));
        const view = gridMode ? form.gridView : form.listView;
        view.positionViewAtIndex(currentIndex, ListView.Contain);
    }
    contentItem: ColumnLayout {
        spacing: Tokens.space12
        LauncherForm {
            id: form
            Layout.fillWidth: true
            Layout.fillHeight: true
            gridMode: root.gridMode
            applications: Shell.search
            appNames: root.applicationNames
            appDescriptions: root.applicationDescriptions
            actionTarget: root
            currentIndex: root.currentIndex
            searchPlaceholder: I18n.t("shell.launcher.placeholder")
            emptyText: I18n.t("shell.launcher.empty")
            searchField.text: Shell.search.query
            searchField.Keys.onPressed: event => {
                if ((event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) && !Shell.applications.preview) {
                    root.requestApplicationMenu(Shell.search.idAt(root.currentIndex));
                    event.accepted = true;
                }
            }
            searchField.Keys.onDownPressed: root.moveSelection(root.gridMode ? Math.max(2, Math.floor(form.gridView.width / Tokens.launcherGridMinimumCell)) : 1)
            searchField.Keys.onUpPressed: root.moveSelection(root.gridMode ? -Math.max(2, Math.floor(form.gridView.width / Tokens.launcherGridMinimumCell)) : -1)
            searchField.Keys.onRightPressed: event => {
                if (root.gridMode && form.searchField.text.length === 0) {
                    root.moveSelection(1);
                    event.accepted = true;
                } else
                    event.accepted = false;
            }
            searchField.Keys.onLeftPressed: event => {
                if (root.gridMode && form.searchField.text.length === 0) {
                    root.moveSelection(-1);
                    event.accepted = true;
                } else
                    event.accepted = false;
            }
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Tokens.surfaceEdge
        }
        Dock {
            id: integratedDock
            Layout.alignment: Qt.AlignHCenter
            decorationVisible: false
            onLauncherRequested: root.close()
            onSettingsRequested: {
                root.close();
                root.settingsRequested();
            }
        }
    }
    Connections {
        target: form.searchField
        function onTextEdited(): void {
            Shell.search.query = form.searchField.text;
        }
        function onAccepted(): void {
            root.activateApp(Shell.search.idAt(root.currentIndex), root.currentIndex);
        }
    }
    Connections {
        target: form.gridButton
        function onClicked(): void {
            root.gridMode = true;
            form.searchField.forceActiveFocus();
        }
    }
    Connections {
        target: form.listButton
        function onClicked(): void {
            root.gridMode = false;
            form.searchField.forceActiveFocus();
        }
    }
    Connections {
        target: form.closeButton
        function onClicked(): void {
            root.close();
        }
    }
    Connections {
        target: Shell.search
        function onQueryChanged(): void {
            root.currentIndex = 0;
        }
    }
}
