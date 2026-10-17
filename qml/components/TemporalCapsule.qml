// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import KLDE.Backends

Button {
    id: root
    // Compatibility for existing preview callers; sizeMode is the public sizing contract.
    property bool compact: true
    property bool showTime: true
    property string sizeMode: compact ? "standard" : "expanded"
    property var readingOverride: null
    readonly property var reading: readingOverride || Shell.time.reading
    readonly property bool rainy: reading.phase === "rainy-evening"
    readonly property bool expanded: sizeMode === "expanded"
    implicitWidth: expanded ? Tokens.temporalExpandedWidth : sizeMode === "compact" ? Tokens.temporalCompactWidth : Tokens.temporalWidth
    implicitHeight: expanded ? Tokens.temporalExpandedHeight : sizeMode === "compact" ? Tokens.temporalCompactHeight : Tokens.temporalHeight
    padding: 0
    Accessible.name: reading.timeText + ", " + I18n.t("temporal.phase." + reading.phase) + ", " + I18n.t("temporal.season." + reading.season) + ", " + I18n.t("temporal.mock")
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
    background: TemporalLandscape {
        sizeMode: root.sizeMode
        reading: root.reading
    }
    contentItem: Item {
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.expanded ? Tokens.space32 : Tokens.space16
            width: parent.width * Tokens.temporalTextRatio
            spacing: Tokens.space4
            Label {
                visible: root.showTime
                width: parent.width
                text: root.reading.timeText
                color: Tokens.temporalText
                horizontalAlignment: Text.AlignHCenter
                font.family: Tokens.displayClockFont
                font.weight: Tokens.displayClockWeight
                font.pixelSize: (root.expanded ? Tokens.temporalExpandedFont : root.sizeMode === "compact" ? Tokens.temporalCompactFont : Tokens.temporalFont) * Tokens.textScale
            }
            Label {
                visible: root.expanded
                width: parent.width
                text: I18n.t("temporal.phase." + root.reading.phase)
                color: Tokens.temporalText
                horizontalAlignment: Text.AlignHCenter
                font: Tokens.caption
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "transparent"
            border.width: root.visualFocus ? Tokens.space2 : Tokens.space1
            border.color: root.visualFocus ? Tokens.primary : root.hovered ? Tokens.temporalText : Tokens.temporalEdge
        }
    }
}
