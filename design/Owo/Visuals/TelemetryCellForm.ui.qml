// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls

Button {
    id: root
    property string iconName: "cpu"
    property string valueText: "18%"
    property int severity: 0
    property bool condensed: false
    width: condensed ? Tokens.telemetryCompactWidth : Tokens.telemetryCellWidth
    height: Tokens.telemetryCellHeight
    padding: 0
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
            Glyph {
                name: root.iconName
                width: Tokens.telemetryIcon
                height: Tokens.telemetryIcon
            }
            Label {
                text: (root.severity > 0 ? "! " : "") + root.valueText
                font: Tokens.caption
                color: root.severity === 2 ? Tokens.error : root.severity === 1 ? Tokens.warning : Tokens.textPrimary
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    background: Rectangle {
        radius: Tokens.radiusS
        color: root.hovered || root.down ? Tokens.primaryContainer : "transparent"
        border.width: root.visualFocus || root.severity > 0 ? Tokens.space1 : 0
        border.color: root.visualFocus ? Tokens.primary : root.severity === 2 ? Tokens.error : Tokens.warning
    }
}
