// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import KLDE.Backends

ApplicationWindow {
    id: window
    property string initialView: "desktop"
    property bool initialDark: false
    property string initialLocale: ""
    property string initialVoice: "standard"
    objectName: "shellWindow"
    width: Tokens.previewWidth
    height: Tokens.previewHeight
    minimumWidth: Tokens.previewMinimumWidth
    minimumHeight: Tokens.previewMinimumHeight
    visible: true
    title: I18n.t("shell.title")
    color: Tokens.background
    font: Tokens.body
    palette.window: Tokens.surface
    palette.windowText: Tokens.textPrimary
    palette.base: Tokens.surfaceElevated
    palette.text: Tokens.textPrimary
    palette.button: Tokens.surfaceContainer
    palette.buttonText: Tokens.textPrimary
    palette.highlight: Tokens.primary
    palette.highlightedText: Tokens.onPrimary
    palette.dark: Tokens.primary
    palette.mid: Tokens.outline
    palette.midlight: Tokens.surfaceContainer
    palette.light: Tokens.surfaceElevated
    palette.shadow: Tokens.shadow

    readonly property bool renderingAllowed: visible && visibility !== Window.Minimized
    onRenderingAllowedChanged: Shell.blur.renderingAllowed = renderingAllowed
    function applyScene(): void {
        const visual = Shell.scenes.current.visual;
        Tokens.darkMode = visual.theme === "auto" ? initialDark : visual.theme === "dark";
        Tokens.transparencyEnabled = visual.transparency;
        Tokens.shadowsEnabled = visual.shadows;
        Tokens.motionLevel = visual.motion;
        Tokens.reducedMotion = visual.motion === 0;
    }
    Connections {
        target: Shell.scenes
        function onCurrentChanged(): void {
            window.applyScene();
        }
    }
    Component.onCompleted: {
        if (initialLocale.length > 0)
            Shell.language.setLocale(initialLocale);
        Shell.language.setVoice(initialVoice);
        applyScene();
        if (initialView === "quick-settings")
            quickSettings.open();
        else if (initialView === "launcher")
            launcher.open();
        else if (initialView === "blur")
            blurLab.open();
        else if (initialView === "power-scenes")
            preferences.open();
        else if (initialView === "weather")
            weatherPreferences.open();
        else if (initialView === "language")
            languagePreferences.open();
        else if (initialView === "input")
            inputPopup.open();
    }

    Item {
        id: wallpaper
        anchors.fill: parent
        Image {
            anchors.fill: parent
            source: "qrc:/assets/wallpapers/first-light.svg"
            sourceSize: Qt.size(width, height)
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle {
            anchors.fill: parent
            color: Tokens.background
            opacity: Tokens.darkMode ? Tokens.darkWallpaperShade : 0
        }
    }
    RowLayout {
        x: Tokens.desktopMargin
        y: Tokens.space24
        spacing: Tokens.space12
        Icon {
            name: "klde"
            Layout.preferredWidth: Tokens.iconL
            Layout.preferredHeight: Tokens.iconL
        }
        ColumnLayout {
            spacing: Tokens.space2
            Label {
                text: "KLDE"
                font: Tokens.title
                color: Tokens.textPrimary
            }
            Label {
                objectName: "statusLabel"
                text: I18n.t("shell.preview")
                font: Tokens.caption
                color: Tokens.textSecondary
            }
        }
    }
    WorkspaceIndicator {
        backdropSource: wallpaper
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.space24
    }
    Button {
        id: quickButton
        objectName: "quickSettingsButton"
        anchors.right: parent.right
        anchors.rightMargin: Tokens.desktopMargin
        y: Tokens.space24
        text: (window.width < Tokens.previewWidth ? "09:41" : I18n.clock()) + " · " + I18n.t("shell.controls.short")
        font: Tokens.label
        Accessible.name: I18n.t("shell.controls.accessible")
        onClicked: quickSettings.opened ? quickSettings.close() : quickSettings.open()
    }
    ActionButton {
        id: inputButton
        objectName: "inputIndicator"
        anchors.right: quickButton.left
        anchors.rightMargin: Tokens.space8
        y: Tokens.space24
        text: Shell.input.indicator
        emphasized: true
        Accessible.name: I18n.t("input.preview")
        ToolTip.visible: hovered
        ToolTip.text: I18n.t("input.preview")
        onClicked: inputPopup.opened ? inputPopup.close() : inputPopup.open()
    }
    WidgetHost {
        widgetId: "weather"
        x: Tokens.desktopMargin
        y: Tokens.controlHeight + Tokens.space32 * 3
        renderingAllowed: window.renderingAllowed
        sourceComponent: Component {
            WeatherWidget {
                weather: Shell.weather
                backdropSource: wallpaper
                onSettingsRequested: weatherPreferences.open()
            }
        }
    }
    ColumnLayout {
        x: Tokens.desktopMargin
        anchors.bottom: dock.top
        anchors.bottomMargin: Tokens.space32
        spacing: Tokens.space8
        Label {
            text: I18n.t("shell.welcome")
            font: Tokens.display
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.t("shell.shortcuts.hint").arg(Shell.shortcuts.launcher).arg(Shell.shortcuts.quickSettings)
            font: Tokens.label
            color: Tokens.textSecondary
        }
    }
    Dock {
        id: dock
        backdropSource: wallpaper
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space24
        onLauncherRequested: launcher.open()
        onSettingsRequested: {
            Shell.launch("settings");
            quickSettings.open();
        }
    }
    Launcher {
        id: launcher
        backdropSource: wallpaper
        parent: Overlay.overlay
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: {
            if (!quickSettings.visible && !blurLab.visible && !preferences.visible && !weatherPreferences.visible && !languagePreferences.visible && !inputPopup.visible)
                dock.focusLauncher();
        }
    }
    QuickSettings {
        id: quickSettings
        backdropSource: wallpaper
        parent: Overlay.overlay
        x: parent ? parent.width - width - Tokens.desktopMargin : 0
        y: Tokens.controlHeight + Tokens.space24 * 2
        onBlurRequested: blurLab.open()
        onSceneSettingsRequested: preferences.open()
        onClosed: {
            if (!launcher.visible && !blurLab.visible && !preferences.visible)
                quickButton.forceActiveFocus();
        }
    }
    BlurLab {
        id: blurLab
        backdropSource: wallpaper
        parent: Overlay.overlay
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: quickButton.forceActiveFocus()
    }
    SceneSettings {
        id: preferences
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: {
            if (!languagePreferences.visible)
                quickButton.forceActiveFocus();
        }
        onLanguageInputRequested: {
            preferences.close();
            languagePreferences.open();
        }
    }
    WeatherSettings {
        id: weatherPreferences
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: quickButton.forceActiveFocus()
    }
    LanguageInputSettings {
        id: languagePreferences
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: inputButton.forceActiveFocus()
    }
    InputPopup {
        id: inputPopup
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? parent.width - width - Tokens.desktopMargin : 0
        y: Tokens.controlHeight + Tokens.space24 * 2
        onSettingsRequested: languagePreferences.open()
        onClosed: {
            if (!languagePreferences.visible)
                inputButton.forceActiveFocus();
        }
    }
    Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dock.top
        anchors.bottomMargin: Tokens.space16
        width: Tokens.panelWidth
        height: noticeText.implicitHeight + Tokens.space32
        opacity: Shell.message.length > 0 ? 1 : 0
        visible: opacity > 0
        Label {
            id: noticeText
            anchors.fill: parent
            text: I18n.s(Shell.message) + (Shell.osdValue >= 0 ? "  " + Shell.osdValue + "%" : "")
            font: Tokens.label
            color: Tokens.textPrimary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.motionFast
            }
        }
    }
    Shortcut {
        sequence: Shell.shortcuts.launcher
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: sequence.length > 0
        onActivated: launcher.opened ? launcher.close() : launcher.open()
    }
    Shortcut {
        sequence: Shell.shortcuts.quickSettings
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: sequence.length > 0
        onActivated: quickSettings.opened ? quickSettings.close() : quickSettings.open()
    }
    Shortcut {
        sequence: Shell.shortcuts.blurLab
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: sequence.length > 0
        onActivated: blurLab.open()
    }
    Shortcut {
        sequence: Shell.shortcuts.reducedMotion
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: sequence.length > 0
        onActivated: Shell.scenes.customize("motion", Tokens.reducedMotion ? 1 : 0)
    }
}
