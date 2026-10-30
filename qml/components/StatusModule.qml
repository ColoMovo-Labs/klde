// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import KLDE.Backends

StatusCapsule {
    id: root
    objectName: "statusModule-" + module.id
    required property var module
    property bool condensed: false
    readonly property var snapshot: Shell.state.snapshot
    readonly property var alerts: Shell.state.alerts
    readonly property string moduleId: module.id
    signal invoked(string moduleId)
    label: I18n.t(module.titleId)
    iconName: moduleId === "weather" ? "weather-" + snapshot.weather.condition : module.icon === "klde" ? Branding.iconName : module.icon
    prominent: moduleId === "time"
    detailed: !condensed && !Shell.ribbon.compact && Tokens.densityMode === 0
    valueText: {
        switch (moduleId) {
        case "weather":
            return snapshot.weather.available ? I18n.number(snapshot.weather.temperature, 0) + "°" : "—";
        case "context":
            return condensed ? "" : snapshot.activeApp === "desktop" ? I18n.t("lab.desktop") : I18n.s(Shell.applications.nameFor(snapshot.activeApp));
        case "date":
            return I18n.date(Shell.time.reading.dateTime, true);
        case "time":
            return Shell.time.reading.timeText;
        case "cpu":
            return I18n.number(snapshot.cpu.usage, 0);
        case "memory":
            return I18n.number(snapshot.memory.usedPercent, 0);
        case "temperature":
            return snapshot.capabilities.sensors ? I18n.number(snapshot.cpu.temperature, 0) + "°" : "—";
        case "battery":
            return snapshot.capabilities.battery ? (snapshot.battery.charging ? "↗ " : "") + I18n.number(snapshot.battery.percent, 0) + "%" : "—";
        case "scene":
            return Tokens.densityMode === 0 ? I18n.t("lab.scene." + snapshot.powerScene) : "";
        case "network":
            return !snapshot.network.enabled ? "×" : !snapshot.network.connected || !snapshot.network.internet ? "!" : snapshot.network.strength < 30 ? I18n.number(snapshot.network.strength, 0) + "%" : "";
        case "bluetooth":
            return snapshot.bluetooth.enabled ? snapshot.bluetooth.connectedDevices > 0 ? snapshot.bluetooth.connectedDevices.toString() : "" : "×";
        case "audio":
            return snapshot.audio.muted ? "×" : condensed || Tokens.densityMode === 2 ? "" : I18n.number(snapshot.audio.volume, 0);
        case "microphone":
            return snapshot.capabilities.microphone ? snapshot.audio.microphoneMuted ? "×" : "" : "—";
        case "input":
            return !snapshot.input.available ? "!" : snapshot.input.currentId === "pinyin" ? snapshot.input.simplified ? "拼" : "繁" : "EN";
        case "notifications":
            return snapshot.notifications.dnd ? "–" : snapshot.notifications.count.toString();
        default:
            return "";
        }
    }
    severity: alerts[moduleId] || 0
    active: moduleId === "input" && snapshot.input.currentId === "pinyin" || moduleId === "network" && snapshot.network.connected || moduleId === "scene"
    unavailable: moduleId === "bluetooth" && !snapshot.capabilities.bluetooth || moduleId === "temperature" && !snapshot.capabilities.sensors || moduleId === "input" && !snapshot.input.available
    meter: moduleId === "cpu" ? snapshot.cpu.usage : moduleId === "memory" ? snapshot.memory.usedPercent : -1
    onClicked: invoked(moduleId)
}
