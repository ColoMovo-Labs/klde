// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

// One settings surface for every owoDE preference. The pages reuse the panel
// contents that previously lived in separate popups.
ShellPopup {
    id: root
    objectName: "settingsCenter"
    signal viewRequested(string view)
    property string page: "appearance"
    readonly property var pages: [
        {
            id: "appearance",
            icon: "sun"
        },
        {
            id: "desktop",
            icon: "grid"
        },
        {
            id: "ribbon",
            icon: "list"
        },
        {
            id: "workspaces",
            icon: "overview"
        },
        {
            id: "shortcuts",
            icon: "terminal"
        },
        {
            id: "displays",
            icon: "display"
        },
        {
            id: "network",
            icon: "wifi"
        },
        {
            id: "sound",
            icon: "volume"
        },
        {
            id: "language",
            icon: "globe"
        },
        {
            id: "power",
            icon: "leaf"
        },
        {
            id: "weather",
            icon: "weather"
        },
        {
            id: "android",
            icon: "folder"
        },
        {
            id: "about",
            icon: "info"
        }
    ]
    readonly property int pageIndex: Math.max(0, pages.findIndex(entry => entry.id === page))
    function openPage(id: string): void {
        if (pages.some(entry => entry.id === id))
            page = id;
    }
    function step(delta: int): void {
        page = pages[(pageIndex + delta + pages.length) % pages.length].id;
    }
    // Moves keyboard focus from the category list into the current page.
    function focusPage(): void {
        const first = firstFocusable(pageLoader.item);
        if (first)
            first.forceActiveFocus(Qt.TabFocusReason);
    }
    function firstFocusable(item: Item): Item {
        if (!item || !item.visible || !item.enabled)
            return null;
        if (item.activeFocusOnTab)
            return item;
        for (const child of item.children) {
            const found = firstFocusable(child);
            if (found)
                return found;
        }
        return null;
    }
    modal: true
    padding: Tokens.space16
    width: Math.min(Tokens.settingsCenterWidth, parent ? parent.width - Tokens.space32 : Tokens.settingsCenterWidth)
    height: Math.min(Tokens.settingsCenterHeight, parent ? parent.height - Tokens.space32 * 2 : Tokens.settingsCenterHeight)
    onOpened: navigation.forceActiveFocus()
    onPageChanged: {
        // Look the index up here: the pageIndex binding may not have been
        // re-evaluated yet when this handler runs.
        navigation.currentIndex = Math.max(0, pages.findIndex(entry => entry.id === page));
        pageScroll.ScrollBar.vertical.position = 0;
        if (!Tokens.reducedMotion)
            pageReveal.restart();
    }
    contentItem: RowLayout {
        spacing: Tokens.space16
        // Ctrl+Tab / Ctrl+Shift+Tab and Ctrl+PageDown / Ctrl+PageUp switch
        // pages from anywhere inside the settings center.
        Shortcut {
            sequences: ["Ctrl+Tab", "Ctrl+PgDown"]
            enabled: root.opened
            onActivated: root.step(1)
        }
        Shortcut {
            sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]
            enabled: root.opened
            onActivated: root.step(-1)
        }
        ListView {
            id: navigation
            objectName: "settingsNavigation"
            Layout.preferredWidth: Tokens.settingsNavWidth
            Layout.fillHeight: true
            model: root.pages
            clip: true
            focus: true
            activeFocusOnTab: true
            keyNavigationEnabled: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: Tokens.space2
            highlightMoveDuration: Tokens.springSpatial.duration
            highlightMoveVelocity: -1
            highlightResizeDuration: 0
            Accessible.role: Accessible.PageTabList
            Accessible.name: I18n.t("settings.title")
            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    root.page = root.pages[currentIndex].id;
            }
            Component.onCompleted: currentIndex = root.pageIndex
            Keys.onRightPressed: root.focusPage()
            Keys.onReturnPressed: root.focusPage()
            Keys.onEnterPressed: root.focusPage()
            header: Label {
                width: navigation.width
                bottomPadding: Tokens.space16
                leftPadding: Tokens.space12
                text: I18n.t("settings.title")
                font: Tokens.headline
                color: Tokens.textPrimary
                elide: Text.ElideRight
            }
            highlight: Rectangle {
                radius: Tokens.radiusPill
                color: Tokens.primaryContainer
                border.width: navigation.activeFocus ? Tokens.space2 : 0
                border.color: Tokens.primary
            }
            delegate: ItemDelegate {
                id: entry
                required property var modelData
                required property int index
                objectName: "settingsPage-" + modelData.id
                width: ListView.view.width
                height: Tokens.controlHeight
                focusPolicy: Qt.NoFocus
                text: I18n.t("settings.page." + modelData.id)
                Accessible.role: Accessible.PageTab
                Accessible.name: text
                Accessible.selected: ListView.isCurrentItem
                onClicked: {
                    navigation.currentIndex = index;
                    navigation.forceActiveFocus();
                }
                background: Rectangle {
                    radius: Tokens.radiusPill
                    color: entry.hovered && !entry.ListView.isCurrentItem ? Tokens.surfaceContainer : "transparent"
                }
                contentItem: RowLayout {
                    spacing: Tokens.space12
                    Icon {
                        name: entry.modelData.icon
                        Layout.preferredWidth: Tokens.iconS
                        Layout.preferredHeight: Tokens.iconS
                    }
                    Label {
                        text: entry.text
                        font: entry.ListView.isCurrentItem ? Tokens.label : Tokens.body
                        color: Tokens.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.space16
            RowLayout {
                Layout.fillWidth: true
                Label {
                    objectName: "settingsHeadline"
                    text: I18n.t("settings.page." + root.page)
                    font: Tokens.display
                    color: Tokens.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Accessible.role: Accessible.Heading
                }
                IconButton {
                    objectName: "settingsClose"
                    iconName: "close"
                    text: I18n.t("settings.close")
                    onClicked: root.close()
                }
            }
            ScrollView {
                id: pageScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true
                Item {
                    id: pageHost
                    width: pageScroll.availableWidth
                    implicitHeight: pageLoader.implicitHeight
                    Loader {
                        id: pageLoader
                        objectName: "settingsPageLoader"
                        width: parent.width
                        sourceComponent: {
                            switch (root.page) {
                            case "desktop":
                                return desktopPage;
                            case "ribbon":
                                return ribbonPage;
                            case "workspaces":
                                return workspacesPage;
                            case "shortcuts":
                                return shortcutsPage;
                            case "displays":
                                return displaysPage;
                            case "network":
                                return networkPage;
                            case "sound":
                                return soundPage;
                            case "language":
                                return languagePage;
                            case "power":
                                return powerPage;
                            case "weather":
                                return weatherPage;
                            case "android":
                                return androidPage;
                            case "about":
                                return aboutPage;
                            }
                            return appearancePage;
                        }
                    }
                    ParallelAnimation {
                        id: pageReveal
                        NumberAnimation {
                            target: pageLoader
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Tokens.springEffects.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Tokens.springEffects.curve
                        }
                        NumberAnimation {
                            target: pageLoader
                            property: "y"
                            from: Tokens.space16
                            to: 0
                            duration: Tokens.springSpatial.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Tokens.springSpatial.curve
                        }
                    }
                }
            }
        }
    }
    Component {
        id: appearancePage
        VisualSettingsContent {
            onLanguageInputRequested: root.openPage("language")
        }
    }
    Component {
        id: desktopPage
        ColumnLayout {
            id: desktopColumn
            readonly property var dockModes: ["smart", "reserve", "hidden"]
            spacing: Tokens.space16
            Label {
                text: I18n.t("settings.dock.mode")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ChoiceBox {
                objectName: "settingsDockMode"
                Layout.fillWidth: true
                model: desktopColumn.dockModes.map(mode => I18n.t("settings.dock.mode." + mode))
                currentIndex: desktopColumn.dockModes.indexOf(Shell.settings.values["dock.mode"])
                Accessible.name: I18n.t("settings.dock.mode")
                onActivated: Shell.settings.setValue("dock.mode", desktopColumn.dockModes[currentIndex])
            }
            Label {
                text: I18n.t("settings.dock.help." + Shell.settings.values["dock.mode"])
                font: Tokens.caption
                color: Tokens.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Switch {
                objectName: "settingsAmbient"
                text: I18n.t("settings.desktop.ambient")
                checked: Shell.state.snapshot.appearance.ambient
                onToggled: Shell.state.requestValue("appearance.ambient", checked)
            }
            WallpaperEffectsSettingsContent {
                Layout.fillWidth: true
                onViewRequested: view => root.viewRequested(view)
            }
        }
    }
    Component {
        id: ribbonPage
        RibbonSettingsContent {}
    }
    Component {
        id: workspacesPage
        WorkspaceSettingsContent {}
    }
    Component {
        id: shortcutsPage
        ShortcutSettingsContent {}
    }
    Component {
        id: displaysPage
        DisplaySettingsContent {}
    }
    Component {
        id: networkPage
        NetworkSettingsContent {}
    }
    Component {
        id: soundPage
        SoundSettingsContent {}
    }
    Component {
        id: languagePage
        LanguageInputSettingsContent {
            onCandidateRequested: root.viewRequested("input-candidate")
        }
    }
    Component {
        id: powerPage
        PowerSettingsContent {}
    }
    Component {
        id: weatherPage
        WeatherSettingsContent {}
    }
    Component {
        id: androidPage
        WaydroidSettingsContent {}
    }
    Component {
        id: aboutPage
        AboutSettingsContent {}
    }
}
