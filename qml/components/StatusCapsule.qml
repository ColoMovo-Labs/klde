// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    required property string label
    property string valueText: ""
    property string iconName: "info"
    property int severity: 0
    property bool active: false
    property bool unavailable: false
    property real meter: -1
    property bool detailed: false
    readonly property color ink: severity === 2 ? Tokens.error : severity === 1 ? Tokens.warning : active ? Tokens.primary : Tokens.textPrimary
    implicitWidth: contentRow.implicitWidth + Tokens.space16
    implicitHeight: Tokens.ribbonHeight
    padding: Tokens.space8
    Accessible.name: label + ", " + valueText + (unavailable ? ", " + I18n.t("lab.unavailable") : "")
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
    contentItem: RowLayout {
        id: contentRow
        spacing: Tokens.space4
        Item {
            implicitWidth: Tokens.ribbonIcon + Tokens.space4
            implicitHeight: Tokens.ribbonIcon + Tokens.space4
            Canvas {
                id: ring
                anchors.fill: parent
                visible: root.meter >= 0
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.lineWidth = Tokens.space3;
                    ctx.strokeStyle = Tokens.outline;
                    ctx.globalAlpha = Tokens.outlineOpacity;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2 - Tokens.space2, 0, 2 * Math.PI);
                    ctx.stroke();
                    ctx.globalAlpha = 1;
                    ctx.strokeStyle = root.ink;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2 - Tokens.space2, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * root.meter / 100);
                    ctx.stroke();
                }
                Connections {
                    target: root
                    function onMeterChanged(): void {
                        ring.requestPaint();
                    }
                    function onInkChanged(): void {
                        ring.requestPaint();
                    }
                }
            }
            Icon {
                anchors.centerIn: parent
                name: root.iconName
                width: root.meter >= 0 ? Tokens.iconS : Tokens.ribbonIcon
                height: width
            }
        }
        Label {
            visible: root.valueText.length > 0 || root.detailed
            text: (root.severity > 0 ? "! " : "") + (root.detailed ? root.label + " " : "") + root.valueText
            color: root.ink
            font: Tokens.label
            elide: Text.ElideRight
            Layout.maximumWidth: root.detailed ? Tokens.widgetSize : Tokens.widgetSize / 2
        }
    }
    background: Rectangle {
        radius: root.active ? Tokens.radiusPill : root.hovered ? Tokens.radiusL : Tokens.radiusM
        color: root.severity === 2 ? Qt.tint(Tokens.surface, Qt.rgba(Tokens.error.r, Tokens.error.g, Tokens.error.b, 0.14)) : root.active || root.hovered ? Tokens.primaryContainer : Tokens.surface
        opacity: root.unavailable ? Tokens.surfaceOpacityLow : Tokens.transparencyEnabled ? Tokens.surfaceOpacityMedium : 1
        border.width: root.visualFocus || root.severity === 2 ? Tokens.space2 : Tokens.space1
        border.color: root.visualFocus || root.severity > 0 ? root.ink : Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
        Behavior on radius {
            NumberAnimation {
                duration: Tokens.motionFast
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Tokens.motionFast
            }
        }
    }
}
