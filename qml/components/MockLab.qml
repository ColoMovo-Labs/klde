// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "mockLab"
    heading: I18n.t("lab.developer.title")
    subtitle: I18n.t("lab.developer.disclosure")
    readonly property var snapshot: Shell.state.snapshot
    signal viewRequested(string view)
    ChoiceBox {
        objectName: "scenarioSelector"
        Layout.fillWidth: true
        model: Shell.mockScenarios.scenarios
        textRole: "titleId"
        displayText: I18n.t(Shell.mockScenarios.scenarios[currentIndex] ? Shell.mockScenarios.scenarios[currentIndex].titleId : "lab.developer.title")
        currentIndex: Shell.mockScenarios.scenarios.findIndex(s => s.id === Shell.mockScenarios.activeId)
        Accessible.name: I18n.t("lab.scenario")
        onActivated: Shell.mockScenarios.apply(Shell.mockScenarios.scenarios[currentIndex].id)
        delegate: ItemDelegate {
            required property var modelData
            width: parent ? parent.width : Tokens.panelWidth
            text: I18n.t(modelData.titleId)
        }
    }
    RowLayout {
        ActionButton {
            text: I18n.t("temporal.title")
            onClicked: root.viewRequested("temporal")
        }
        ActionButton {
            text: I18n.t("wallpaper.title")
            onClicked: root.viewRequested("wallpaper-effects")
        }
        ActionButton {
            text: I18n.t("android.title")
            onClicked: root.viewRequested("waydroid")
        }
    }
    StateChoice {
        label: I18n.t("language.locale")
        path: "locale"
        values: ["zh_CN", "en"]
        labels: [I18n.t("language.chinese"), I18n.t("language.english")]
    }
    StateChoice {
        label: I18n.t("language.voice")
        path: "voice"
        values: ["standard", "cute"]
        labels: [I18n.t("language.standard"), I18n.t("language.cute")]
    }
    RowLayout {
        Switch {
            text: I18n.t("common.dark")
            checked: Tokens.darkMode
            onToggled: Shell.scenes.customize("theme", checked ? "dark" : "light")
        }
        Switch {
            text: I18n.t("lab.ambient")
            checked: root.snapshot.appearance.ambient
            onToggled: Shell.state.requestValue("appearance.ambient", checked)
        }
    }
    StateChoice {
        label: I18n.t("lab.wallpaper")
        path: "appearance.wallpaper"
        values: ["snow", "abstract", "quiet", "kemono"]
        labels: [I18n.t("lab.wallpaper.snow"), I18n.t("lab.wallpaper.abstract"), I18n.t("lab.wallpaper.quiet"), I18n.t("lab.wallpaper.kemono")]
    }
    Label {
        text: I18n.t("shell.effects.accent")
        color: Tokens.textPrimary
        font: Tokens.label
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("common.auto"), I18n.t("shell.effects.teal"), I18n.t("shell.effects.lilac"), I18n.t("shell.effects.apricot")]
        currentIndex: ["auto", "teal", "lilac", "apricot"].indexOf(Tokens.accentChoice)
        onActivated: Tokens.accentChoice = ["auto", "teal", "lilac", "apricot"][currentIndex]
    }
    StateChoice {
        label: I18n.t("shell.scene.select")
        path: "powerScene"
        values: ["performance", "balanced", "power-saver"]
        labels: [I18n.t("lab.scene.performance"), I18n.t("lab.scene.balanced"), I18n.t("lab.scene.power-saver")]
    }
    Label {
        text: I18n.t("shell.scene.blur")
        color: Tokens.textPrimary
        font: Tokens.label
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("common.off"), I18n.t("common.low"), I18n.t("common.medium"), I18n.t("common.high")]
        currentIndex: Shell.scenes.current.visual.blurEnabled ? Shell.scenes.current.visual.blurQuality : 0
        onActivated: {
            Shell.scenes.customize("blurEnabled", currentIndex !== 0);
            if (currentIndex > 0)
                Shell.scenes.customize("blurQuality", currentIndex);
        }
    }
    Label {
        text: I18n.t("lab.density")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("lab.density.comfortable"), I18n.t("lab.density.balanced"), I18n.t("lab.density.dense")]
        currentIndex: Tokens.densityMode
        onActivated: Shell.scenes.customize("density", currentIndex)
    }
    Label {
        text: I18n.t("shell.effects.motion")
        color: Tokens.textPrimary
        font: Tokens.label
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("common.reduced"), I18n.t("common.normal"), I18n.t("common.expressive"), I18n.t("lab.motion.fast")]
        currentIndex: Tokens.motionLevel
        onActivated: Shell.scenes.customize("motion", currentIndex)
    }
    StateSlider {
        visible: root.snapshot.capabilities.battery
        label: I18n.t("lab.module.battery")
        path: "battery.percent"
        iconName: "battery"
    }
    Switch {
        visible: root.snapshot.capabilities.battery
        text: I18n.t("lab.battery.charging")
        checked: root.snapshot.battery.charging
        onToggled: Shell.state.requestValue("battery.charging", checked)
    }
    StateSlider {
        label: I18n.t("lab.module.cpu")
        path: "cpu.usage"
        iconName: "cpu"
    }
    StateSlider {
        label: I18n.t("lab.module.memory")
        path: "memory.usedPercent"
        iconName: "memory"
    }
    StateSlider {
        visible: root.snapshot.capabilities.sensors
        label: I18n.t("lab.module.temperature")
        path: "cpu.temperature"
        iconName: "thermometer"
    }
    RowLayout {
        Switch {
            text: I18n.t("shell.network.wifi")
            checked: root.snapshot.network.enabled
            onToggled: Shell.state.requestValue("network.enabled", checked)
        }
        Switch {
            visible: root.snapshot.capabilities.bluetooth
            text: I18n.t("shell.network.bluetooth")
            checked: root.snapshot.bluetooth.enabled
            onToggled: Shell.state.requestValue("bluetooth.enabled", checked)
        }
    }
    StateSlider {
        label: I18n.t("shell.effects.volume")
        path: "audio.volume"
        iconName: "volume"
    }
    StateSlider {
        visible: root.snapshot.capabilities.microphone
        label: I18n.t("lab.module.microphone")
        path: "audio.microphone"
        iconName: "microphone"
    }
    StateSlider {
        visible: root.snapshot.capabilities.brightness
        label: I18n.t("shell.effects.brightness")
        path: "brightness"
        iconName: "sun"
    }
    StateChoice {
        label: I18n.t("lab.module.input")
        path: "input.currentId"
        values: ["keyboard-us", "pinyin"]
        labels: [I18n.t("input.english"), I18n.t("input.pinyin")]
    }
    StateChoice {
        label: I18n.t("lab.module.weather")
        path: "weather.condition"
        values: ["clear", "partly-cloudy", "cloudy", "rain", "thunderstorm", "snow", "fog", "extreme-heat", "extreme-cold"]
        labels: values.map(v => I18n.t("weather.condition." + v))
    }
    StateChoice {
        label: I18n.t("lab.center.count-label")
        path: "notifications.count"
        values: [0, 1, 3, 6, 12]
        labels: ["0", "1", "3", "6", "12"]
    }
    StateChoice {
        label: I18n.t("lab.workspace")
        path: "workspaces.active"
        values: [1, 2, 3, 4, 5]
        labels: ["1", "2", "3", "4", "5"]
    }
    Label {
        text: I18n.t("lab.workspace.layout")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("shell.workspace.floating"), I18n.t("shell.workspace.tiled"), I18n.t("shell.workspace.mixed"), I18n.t("lab.workspace.scrolling")]
        currentIndex: root.snapshot.workspaces.layouts[root.snapshot.workspaces.active - 1]
        onActivated: {
            const layouts = root.snapshot.workspaces.layouts.slice();
            layouts[root.snapshot.workspaces.active - 1] = currentIndex;
            Shell.state.requestValue("workspaces.layouts", layouts);
        }
    }
    StateChoice {
        label: I18n.t("lab.module.context")
        path: "activeApp"
        values: ["desktop", "files", "web", "terminal", "notes", "music", "settings"]
        labels: values.map(v => v === "desktop" ? I18n.t("lab.desktop") : I18n.s(Shell.applications.nameFor(v)))
    }
    ActionButton {
        text: I18n.t("lab.time.advance")
        onClicked: Shell.state.advanceMinutes(1)
    }
    Flow {
        Layout.fillWidth: true
        spacing: Tokens.space8
        ActionButton {
            text: I18n.t("lab.ribbon.customize")
            onClicked: root.viewRequested("ribbon-settings")
        }
        ActionButton {
            text: I18n.t("lab.apps.title")
            onClicked: root.viewRequested("app-suite")
        }
    }
}
