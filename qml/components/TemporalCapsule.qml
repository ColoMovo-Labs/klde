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
    readonly property int contentInset: expanded ? Tokens.temporalExpandedInset : sizeMode === "compact" ? Tokens.temporalCompactInset : Tokens.temporalInset
    readonly property Item debugContentItem: textColumn
    readonly property Item debugTextItem: timeLabel
    implicitWidth: expanded ? Tokens.temporalExpandedWidth : sizeMode === "compact" ? Tokens.temporalCompactWidth : Tokens.temporalWidth
    implicitHeight: expanded ? Tokens.temporalExpandedHeight : sizeMode === "compact" ? Tokens.temporalCompactHeight : Tokens.temporalHeight
    Behavior on width {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
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
            id: textColumn
            objectName: "temporalTextColumn"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - root.contentInset * 2
            spacing: Tokens.space4
            Label {
                id: timeLabel
                visible: root.showTime
                objectName: "temporalTimeText"
                width: parent.width
                text: root.reading.timeText
                color: Tokens.temporalText
                horizontalAlignment: Text.AlignHCenter
                font.family: Tokens.displayClockFont
                font.weight: Tokens.displayClockWeight
                font.pixelSize: (root.expanded ? Tokens.temporalExpandedFont : root.sizeMode === "compact" ? Tokens.temporalCompactFont : Tokens.temporalFont) * Tokens.textScale
            }
            Label {
                id: phaseLabel
                visible: root.expanded || opacity > 0.001
                opacity: root.expanded ? 1 : 0
                objectName: "temporalPhaseText"
                width: parent.width
                text: I18n.t("temporal.phase." + root.reading.phase)
                color: Tokens.temporalText
                horizontalAlignment: Text.AlignHCenter
                font: Tokens.caption
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.springEffectsFast.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Tokens.springEffectsFast.curve
                    }
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "transparent"
            border.width: root.visualFocus ? Tokens.space2 : Tokens.space1
            border.color: root.visualFocus ? Tokens.primary : root.hovered ? Tokens.temporalText : Tokens.temporalEdge
        }
        GeometryDebugOverlay {
            anchors.fill: parent
            debugEnabled: Tokens.debugGeometry
            targetItems: [root]
            contentItems: [textColumn]
            textItems: [timeLabel, phaseLabel]
        }
    }
}
