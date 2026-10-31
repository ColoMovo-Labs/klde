// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

TelemetryCellForm {
    id: root
    required property string moduleId
    readonly property var cells: Shell.telemetry.cells
    readonly property var reading: cells.find(c => c.id === moduleId) || ({
            value: "—",
            severity: 0,
            available: false
        })
    iconName: moduleId === "temperature" ? "thermometer" : moduleId
    valueText: reading.value
    severity: reading.severity
    readonly property bool live: Shell.state.livePaths.some(path => path.startsWith(moduleId === "temperature" ? "cpu.temperature" : moduleId + "."))
    Accessible.name: (live ? "" : I18n.t("settings.mock.badge") + ", ") + I18n.t("lab.module." + moduleId) + ", " + reading.value + (reading.available ? "" : ", " + I18n.t("lab.unavailable"))
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
}
