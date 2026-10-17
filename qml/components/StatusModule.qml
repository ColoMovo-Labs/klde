// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import KLDE.Backends

StatusCapsule {
    id: root
    required property var module
    readonly property var state: Shell.state.snapshot
    readonly property var alerts: Shell.state.alerts
    readonly property string moduleId: module.id
    signal action(string moduleId)
    label: I18n.t(module.titleId)
    iconName: module.icon
    detailed: !Shell.ribbon.compact && Tokens.densityMode === 0
    valueText: {
        switch (moduleId) {
        case "weather":
            return state.weather.available ? I18n.number(state.weather.temperature, 0) + "°" : "—";
        case "context":
            return state.activeApp === "desktop" ? I18n.t("lab.desktop") : I18n.s(Shell.applications.nameFor(state.activeApp));
        case "date":
            return Qt.formatDate(new Date(state.time), I18n.locale === "zh_CN" ? "M月d日 ddd" : "MMM d, ddd");
        case "time":
            return Qt.formatTime(new Date(state.time), "hh:mm");
        case "cpu":
            return I18n.number(state.cpu.usage, 0);
        case "memory":
            return I18n.number(state.memory.usedPercent, 0);
        case "temperature":
            return state.capabilities.sensors ? I18n.number(state.cpu.temperature, 0) + "°" : "—";
        case "battery":
            return state.capabilities.battery ? (state.battery.charging ? "↗ " : "") + I18n.number(state.battery.percent, 0) + "%" : "—";
        case "scene":
            return Tokens.densityMode === 0 ? I18n.t("lab.scene." + state.powerScene) : "";
        case "network":
            return state.network.enabled ? state.network.connected ? "" : "!" : "×";
        case "bluetooth":
            return state.bluetooth.enabled ? state.bluetooth.connectedDevices > 0 ? state.bluetooth.connectedDevices.toString() : "" : "×";
        case "audio":
            return state.audio.muted ? "×" : Tokens.densityMode === 2 ? "" : I18n.number(state.audio.volume, 0);
        case "microphone":
            return state.capabilities.microphone ? state.audio.microphoneMuted ? "×" : "" : "—";
        case "input":
            return !state.input.available ? "!" : state.input.currentId === "pinyin" ? state.input.simplified ? "拼" : "繁" : "EN";
        case "notifications":
            return state.notifications.dnd ? "–" : state.notifications.count.toString();
        default:
            return "";
        }
    }
    severity: alerts[moduleId] || 0
    active: moduleId === "input" && state.input.currentId === "pinyin" || moduleId === "network" && state.network.connected || moduleId === "scene"
    unavailable: moduleId === "bluetooth" && !state.capabilities.bluetooth || moduleId === "temperature" && !state.capabilities.sensors || moduleId === "input" && !state.input.available
    meter: moduleId === "cpu" ? state.cpu.usage : moduleId === "memory" ? state.memory.usedPercent : -1
    onClicked: action(moduleId)
}
