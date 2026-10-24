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
    property string initialVoice: ""
    property string initialScenario: "laptop-balanced"
    property int initialDensity: 1
    property string initialWallpaper: "snow"
    property bool initialAmbient: false
    property bool initialFocus: false
    property string initialLockState: "ambient"
    property string initialIslandState: "idle"
    property int initialWelcomePage: 0
    property bool initialDebugGeometry: false
    property bool developerTools: false
    property bool nativeSurfaceMode: false
    objectName: "shellWindow"
    width: Tokens.previewWidth
    height: Tokens.previewHeight
    minimumWidth: Tokens.previewMinimumWidth
    minimumHeight: Tokens.previewMinimumHeight
    // In native-surface mode this controller window is hidden; the wallpaper,
    // ribbon and dock are separate LayerShellQt-backed QWindows below.
    visible: !nativeSurfaceMode
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
    palette.highlightedText: Tokens.textOnPrimary
    palette.dark: Tokens.primary
    palette.mid: Tokens.outline
    palette.midlight: Tokens.surfaceContainer
    palette.light: Tokens.surfaceElevated
    palette.shadow: Tokens.shadow

    readonly property bool renderingAllowed: visible && visibility !== Window.Minimized
    readonly property bool lockSurfaceMode: initialView === "lock-screen"
    readonly property bool welcomeMode: initialView === "welcome"
    readonly property var snapshot: Shell.state.snapshot
    readonly property real popupTop: ribbon.y + ribbon.height + Tokens.space16
    readonly property var panels: [launcher, quickSettings, blurLab, preferences, weatherPreferences, languagePreferences, inputPopup, notificationCenter, statusDashboard, ribbonSettings, candidate, mockLab, appSuite, systemUiGallery, temporalSettings, wallpaperSettings, lockPreview, waydroidSettings]
    onRenderingAllowedChanged: Shell.blur.renderingAllowed = renderingAllowed
    function applyScene(): void {
        const visual = Shell.scenes.current.visual;
        Tokens.darkMode = visual.theme === "auto" ? initialDark : visual.theme === "dark";
        Tokens.transparencyEnabled = visual.transparency;
        Tokens.shadowsEnabled = visual.shadows;
        Tokens.shadowLevel = visual.shadowLevel;
        Tokens.motionLevel = visual.motion;
        Tokens.reducedMotion = visual.motion === 0;
        Tokens.densityMode = visual.density;
    }
    function showView(view: string): void {
        let target = null;
        switch (view) {
        case "temporal":
            target = temporalSettings;
            break;
        case "wallpaper-effects":
            target = wallpaperSettings;
            break;
        case "lock-preview":
            target = lockPreview;
            break;
        case "waydroid":
            target = waydroidSettings;
            break;
        case "launcher":
            target = launcher;
            break;
        case "quick-settings-expanded":
            quickSettings.expanded = true;
            target = quickSettings;
            break;
        case "quick-settings":
            target = quickSettings;
            break;
        case "blur":
            target = blurLab;
            break;
        case "power-scenes":
            target = preferences;
            break;
        case "weather":
            target = weatherPreferences;
            break;
        case "language":
            target = languagePreferences;
            break;
        case "input":
            target = inputPopup;
            break;
        case "weather-preview":
            notificationCenter.tab = 2;
            target = notificationCenter;
            break;
        case "notifications":
            notificationCenter.tab = window.snapshot.weather.available ? 0 : 2;
            target = notificationCenter;
            break;
        case "ribbon":
            target = statusDashboard;
            break;
        case "ribbon-settings":
            target = ribbonSettings;
            break;
        case "input-candidate":
            target = candidate;
            break;
        case "mock-lab":
            target = mockLab;
            break;
        case "app-suite":
            target = appSuite;
            break;
        case "gallery":
            target = systemUiGallery;
            break;
        }
        const close = target && target.opened;
        for (const panel of panels)
            if (panel !== target)
                panel.close();
        if (target)
            close ? target.close() : target.open();
    }
    function moduleAction(id: string): void {
        if (id === "launcher")
            showView("launcher");
        else if (id === "overview" || id === "context" || id === "notifications" || id === "date")
            showView("notifications");
        else if (id === "weather")
            showView("weather");
        else if (id === "input")
            showView("input");
        else if (id === "scene")
            showView("power-scenes");
        else if (id === "time")
            showView("temporal");
        else if (id === "cpu" || id === "memory" || id === "temperature" || id === "battery")
            showView("ribbon");
        else if (id === "power")
            Shell.system.requestSessionAction("shutdown");
        else
            showView("quick-settings");
    }
    Connections {
        target: Shell.scenes
        function onCurrentChanged(): void {
            window.applyScene();
        }
    }
    Connections {
        target: Shell
        function onLauncherRequested(): void {
            if (!launcher.opened)
                window.showView("launcher");
        }
    }
    Component.onCompleted: {
        Shell.mockScenarios.apply(initialScenario);
        if (initialLocale.length > 0)
            Shell.language.setLocale(initialLocale);
        if (initialVoice.length > 0)
            Shell.language.setVoice(initialVoice);
        Shell.scenes.customize("density", initialDensity);
        Shell.state.requestValue("appearance.wallpaper", initialWallpaper);
        if (initialAmbient)
            Shell.state.requestValue("appearance.ambient", true);
        if (initialFocus)
            Shell.state.requestValue("appearance.focus", true);
        Tokens.debugGeometry = initialDebugGeometry;
        applyScene();
        showView(developerTools ? "mock-lab" : initialView);
    }
    Binding {
        target: Tokens
        property: "wallpaperChoice"
        value: window.snapshot.appearance.wallpaper
    }
    WallpaperLayers {
        id: wallpaper
        anchors.fill: parent
        visible: !window.nativeSurfaceMode
    }
    StatusRibbon {
        id: ribbon
        objectName: "statusRibbon"
        visible: !window.nativeSurfaceMode && !window.welcomeMode && Shell.ribbon.enabled
        x: Shell.ribbon.margin
        y: Shell.ribbon.margin
        width: parent.width - x * 2
        height: implicitHeight
        islandState: window.initialIslandState
        onAction: moduleId => window.moduleAction(moduleId)
    }
    Label {
        objectName: "statusLabel"
        x: Tokens.desktopMargin
        y: window.popupTop
        text: I18n.t("lab.preview")
        color: Tokens.textSecondary
        font: Tokens.caption
    }
    WidgetHost {
        widgetId: "weather"
        visible: !window.welcomeMode && !window.snapshot.appearance.ambient
        x: Tokens.desktopMargin
        y: window.popupTop + Tokens.controlHeight
        renderingAllowed: window.renderingAllowed
        sourceComponent: Component {
            WeatherWidget {
                weather: Shell.weather
                backdropSource: wallpaper
                onSettingsRequested: window.showView("weather")
            }
        }
    }
    ColumnLayout {
        visible: !window.welcomeMode && !window.snapshot.appearance.ambient && window.snapshot.activeApp === "desktop"
        x: Tokens.desktopMargin
        anchors.bottom: dock.top
        anchors.bottomMargin: Tokens.space32
        width: parent.width - Tokens.desktopMargin * 2
        spacing: Tokens.space8
        Label {
            text: I18n.t("shell.welcome")
            font: Tokens.display
            color: Tokens.textPrimary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Label {
            text: I18n.t("lab.desktop.hint")
            font: Tokens.label
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
    AmbientDesktop {
        objectName: "desktopClockLayer"
        visible: !window.welcomeMode && window.snapshot.appearance.ambient
        x: Tokens.desktopMargin
        y: window.popupTop + Tokens.space24
        width: parent.width - Tokens.desktopMargin * 2
        height: dock.y - y - Tokens.space24
    }
    WallpaperLayers {
        anchors.fill: parent
        foregroundOnly: true
        visible: !window.nativeSurfaceMode && !window.welcomeMode && window.snapshot.appearance.ambient
    }
    Surface {
        visible: !window.welcomeMode && window.snapshot.scratchpad
        anchors.centerIn: parent
        width: Math.min(Tokens.panelWidth, parent.width - Tokens.space32)
        height: Tokens.widgetSize
        ColumnLayout {
            anchors.fill: parent
            Label {
                text: I18n.t("lab.scratchpad.title")
                font: Tokens.title
                color: Tokens.textPrimary
            }
            TextArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: I18n.t("lab.scratchpad.hint")
                font: Tokens.body
                wrapMode: TextEdit.Wrap
                Accessible.name: I18n.t("lab.scratchpad.title")
            }
        }
    }
    Dock {
        id: dock
        visible: !window.nativeSurfaceMode && !window.welcomeMode && !window.snapshot.appearance.focus
        backdropSource: wallpaper
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space24
        onLauncherRequested: window.showView("launcher")
        onSettingsRequested: window.showView("quick-settings")
    }
    Launcher {
        id: launcher
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: dock.focusLauncher()
    }
    QuickSettings {
        id: quickSettings
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? parent.width - width - Shell.ribbon.margin : 0
        y: window.popupTop
        onBlurRequested: window.showView("blur")
        onSceneSettingsRequested: window.showView("power-scenes")
        onViewRequested: view => window.showView(view)
    }
    BlurLab {
        id: blurLab
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    SceneSettings {
        id: preferences
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onLanguageInputRequested: window.showView("language")
    }
    WeatherSettings {
        id: weatherPreferences
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    LanguageInputSettings {
        id: languagePreferences
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onCandidateRequested: window.showView("input-candidate")
    }
    InputPopup {
        id: inputPopup
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? parent.width - width - Shell.ribbon.margin : 0
        y: window.popupTop
        onSettingsRequested: window.showView("language")
    }
    NotificationCenter {
        id: notificationCenter
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: Shell.ribbon.margin
        y: window.popupTop
        height: parent ? parent.height - y - Tokens.space24 : Tokens.settingsHeight
        onWeatherRequested: window.showView("weather")
    }
    StatusDashboard {
        id: statusDashboard
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: window.popupTop
        onCustomizeRequested: window.showView("ribbon-settings")
    }
    RibbonSettings {
        id: ribbonSettings
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    CandidatePreview {
        id: candidate
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    MockLab {
        id: mockLab
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onViewRequested: view => window.showView(view)
    }
    AppSuitePreview {
        id: appSuite
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    SystemUiGallery {
        id: systemUiGallery
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    TemporalSettings {
        id: temporalSettings
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    WallpaperEffectsSettings {
        id: wallpaperSettings
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onViewRequested: view => window.showView(view)
    }
    LockScreenPreview {
        id: lockPreview
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    LockScreenSurface {
        id: lockSurface
        anchors.fill: parent
        visible: window.lockSurfaceMode
        z: 1000
        stateName: window.initialLockState
    }
    WelcomeFlow {
        id: welcomeFlow
        anchors.fill: parent
        visible: window.welcomeMode
        z: 1000
        backdropSource: wallpaper
        pageIndex: window.initialWelcomePage
        offline: !window.snapshot.network.internet
        onFinished: window.initialView = "desktop"
    }
    WaydroidSettings {
        id: waydroidSettings
        parent: Overlay.overlay
        backdropSource: wallpaper
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
    }
    Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dock.top
        anchors.bottomMargin: Tokens.space16
        width: Math.min(Tokens.panelWidth, parent.width - Tokens.space32)
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
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
        }
    }
    TemporalStudy {
        visible: window.initialView === "temporal-study"
        anchors.fill: parent
        z: 100
    }
    Loader {
        anchors.fill: parent
        z: 100
        active: window.initialView === "material-study"
        sourceComponent: Component {
            MaterialStudy {}
        }
    }
    ApplicationShortcuts {
        onAction: id => {
            if (id === "shell.launcher" || id === "shell.super-launcher")
                window.showView("launcher");
            else if (id === "shell.quick-settings")
                window.showView("quick-settings");
            else if (id === "preview.blur-lab")
                window.showView("blur");
            else if (id === "shell.mock-lab")
                window.showView("mock-lab");
            else if (id === "shell.notifications")
                window.showView("notifications");
            else if (id === "effects.reduced-motion")
                Shell.scenes.customize("motion", Tokens.reducedMotion ? 2 : 0);
            else
                Shell.previewAction(id);
        }
    }

    // These windows are intentionally small and explicit. They are the first
    // native-surface slice; all panels/popups remain owned by the ordinary
    // preview until their input/focus contracts are migrated separately.
    // Keep these QWindows unloaded in preview mode. That prevents duplicate
    // object names from changing Visual Lab geometry queries and keeps the
    // ordinary preview a single xdg-toplevel window.
    Component {
        id: nativeWallpaperComponent
        Window {
            id: nativeWallpaperSurface
            objectName: "nativeWallpaperSurface"
            visible: false
            flags: Qt.FramelessWindowHint | Qt.Tool
            color: "transparent"
            width: window.width
            height: window.height
            WallpaperLayers {
                anchors.fill: parent
                visible: true
            }
            Component.onCompleted: {
                if (Shell.surface.attach(nativeWallpaperSurface, "wallpaper"))
                    visible = true;
            }
        }
    }
    Loader {
        id: nativeWallpaperLoader
        active: window.nativeSurfaceMode
        sourceComponent: nativeWallpaperComponent
    }

    Component {
        id: nativeRibbonComponent
        Window {
            id: nativeRibbonSurface
            objectName: "nativeRibbonSurface"
            visible: false
            flags: Qt.FramelessWindowHint | Qt.Tool
            color: "transparent"
            width: window.width
            height: Tokens.ribbonBandHeight + Tokens.space32
            StatusRibbon {
                anchors.fill: parent
                anchors.margins: Tokens.space16
                islandState: window.initialIslandState
                onAction: moduleId => window.moduleAction(moduleId)
            }
            Component.onCompleted: {
                if (Shell.surface.attach(nativeRibbonSurface, "ribbon"))
                    visible = true;
            }
        }
    }
    Loader {
        id: nativeRibbonLoader
        active: window.nativeSurfaceMode
        sourceComponent: nativeRibbonComponent
    }

    Component {
        id: nativeDockComponent
        Window {
            id: nativeDockSurface
            objectName: "nativeDockSurface"
            visible: false
            flags: Qt.FramelessWindowHint | Qt.Tool
            color: "transparent"
            width: window.width
            height: Tokens.dockHeight + Tokens.space32 + Tokens.space16
            Dock {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.space24
                onLauncherRequested: window.showView("launcher")
                onSettingsRequested: window.showView("quick-settings")
            }
            Component.onCompleted: {
                if (Shell.surface.attach(nativeDockSurface, "dock"))
                    visible = true;
            }
        }
    }
    Loader {
        id: nativeDockLoader
        active: window.nativeSurfaceMode
        sourceComponent: nativeDockComponent
    }
}
