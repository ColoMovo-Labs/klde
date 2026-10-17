// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Button {
    id: root
    required property string moduleId
    readonly property var cells: Shell.telemetry.cells
    readonly property var reading: cells.find(c => c.id === moduleId) || ({
            value: "—",
            severity: 0,
            available: false
        })
    width: Tokens.telemetryCellWidth
    height: Tokens.telemetryCellHeight
    padding: Tokens.space4
    Accessible.name: I18n.t("lab.module." + moduleId) + ", " + reading.value + (reading.available ? "" : ", " + I18n.t("lab.unavailable"))
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
    contentItem: RowLayout {
        spacing: Tokens.space4
        Icon {
            name: root.moduleId === "temperature" ? "thermometer" : root.moduleId
            Layout.preferredWidth: Tokens.iconS
            Layout.preferredHeight: Tokens.iconS
        }
        Label {
            text: (root.reading.severity > 0 ? "! " : "") + root.reading.value
            font: Tokens.caption
            color: root.reading.severity === 2 ? Tokens.error : root.reading.severity === 1 ? Tokens.warning : Tokens.textPrimary
            Layout.fillWidth: true
        }
    }
    background: Rectangle {
        radius: Tokens.radiusS
        color: root.hovered || root.down ? Tokens.primaryContainer : "transparent"
        border.width: root.visualFocus || root.reading.severity > 0 ? Tokens.space1 : 0
        border.color: root.visualFocus ? Tokens.primary : root.reading.severity === 2 ? Tokens.error : Tokens.warning
    }
}
