// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Button {
    id: root
    required property string moduleId
    property bool condensed: false
    readonly property var cells: Shell.telemetry.cells
    readonly property var reading: cells.find(c => c.id === moduleId) || ({
            value: "—",
            severity: 0,
            available: false
        })
    width: condensed ? Tokens.telemetryCompactWidth : Tokens.telemetryCellWidth
    height: Tokens.telemetryCellHeight
    padding: 0
    Accessible.name: I18n.t("lab.preview") + ", " + I18n.t("lab.module." + moduleId) + ", " + reading.value + (reading.available ? "" : ", " + I18n.t("lab.unavailable"))
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
    // Keep each telemetry pair centered inside its fixed cell.  A fill-width
    // label made the pair start at the cell edge, which was especially visible
    // in the two-column monitoring capsule beside the clock.
    contentItem: Item {
        implicitWidth: cellRow.implicitWidth
        implicitHeight: cellRow.implicitHeight
        Row {
            id: cellRow
            anchors.centerIn: parent
            spacing: Tokens.capsuleIconTextGap
            Icon {
                name: root.moduleId === "temperature" ? "thermometer" : root.moduleId
                width: Tokens.telemetryIcon
                height: Tokens.telemetryIcon
            }
            Label {
                text: (root.reading.severity > 0 ? "! " : "") + root.reading.value
                font: Tokens.caption
                color: root.reading.severity === 2 ? Tokens.error : root.reading.severity === 1 ? Tokens.warning : Tokens.textPrimary
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    background: Rectangle {
        radius: Tokens.radiusS
        color: root.hovered || root.down ? Tokens.primaryContainer : "transparent"
        border.width: root.visualFocus || root.reading.severity > 0 ? Tokens.space1 : 0
        border.color: root.visualFocus ? Tokens.primary : root.reading.severity === 2 ? Tokens.error : Tokens.warning
    }
}
