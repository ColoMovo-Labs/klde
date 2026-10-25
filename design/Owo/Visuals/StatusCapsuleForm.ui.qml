// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property real shapeRadius: root.active || root.prominent ? Tokens.radiusPill : root.hovered ? Tokens.radiusL : Tokens.radiusM
    property color shapeColor: root.grouped && !root.hovered && !root.visualFocus && root.severity === 0 ? "transparent" : root.prominent ? Tokens.primary : root.severity === 2 ? Qt.tint(Tokens.surface, Qt.rgba(Tokens.error.r, Tokens.error.g, Tokens.error.b, 0.14)) : root.active || root.hovered ? Tokens.primaryContainer : Tokens.surface
    property alias meterHost: meterSlot
    property string unavailableText: "Unavailable"
    property string label: "Status"
    property string valueText: ""
    property string iconName: "info"
    property int severity: 0
    property bool active: false
    property bool prominent: false
    property bool unavailable: false
    property real meter: -1
    property bool detailed: false
    property bool grouped: false
    readonly property color ink: prominent ? Tokens.textOnPrimary : severity === 2 ? Tokens.error : severity === 1 ? Tokens.warning : active ? Tokens.primary : Tokens.textPrimary
    implicitWidth: Math.max(Tokens.controlHeight, contentRow.implicitWidth + Tokens.capsuleHorizontalPadding * 2)
    implicitHeight: Tokens.ribbonHeight
    leftPadding: Tokens.capsuleHorizontalPadding
    rightPadding: Tokens.capsuleHorizontalPadding
    topPadding: Tokens.capsuleVerticalPadding
    bottomPadding: Tokens.capsuleVerticalPadding
    Accessible.name: label + ", " + valueText + (unavailable ? ", " + root.unavailableText : "")
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Tokens.capsuleIconTextGap
            Item {
                // The row already owns the icon/text gap.  Keeping the slot at the
                // icon size prevents a second invisible gap from pulling labels
                // outward and makes icon-only capsules optically centered.
                implicitWidth: Tokens.capsuleIconSize
                implicitHeight: Tokens.capsuleIconSize
                Item {
                    id: meterSlot
                    anchors.fill: parent
                }

                Glyph {
                    anchors.centerIn: parent
                    name: root.iconName
                    lightInk: root.prominent ? !Tokens.darkMode : Tokens.darkMode
                    width: root.meter >= 0 ? Tokens.iconS : Tokens.capsuleIconSize
                    height: width
                }
            }
            Label {
                visible: root.valueText.length > 0 || root.detailed
                text: (root.severity > 0 ? "! " : "") + (root.detailed ? root.label + " " : "") + root.valueText
                color: root.ink
                font: Tokens.label
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Layout.maximumWidth: root.detailed ? Tokens.widgetSize : Tokens.widgetSize / 2
            }
        }
    }
    background: Rectangle {
        radius: root.shapeRadius
        color: root.shapeColor
        opacity: root.unavailable ? Tokens.surfaceOpacityLow : Tokens.transparencyEnabled ? Tokens.surfaceOpacityMedium : 1
        border.width: root.visualFocus || root.severity === 2 ? Tokens.space2 : root.grouped ? 0 : Tokens.capsuleBorderWidth
        border.color: root.visualFocus || root.severity > 0 ? root.ink : Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
    }
}
