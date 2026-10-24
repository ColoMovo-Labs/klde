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
    Accessible.name: label + ", " + valueText + (unavailable ? ", " + I18n.t("lab.unavailable") : "")
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
    scale: root.down ? Tokens.pressScale : root.hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
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
        radius: root.active || root.prominent ? Tokens.radiusPill : root.hovered ? Tokens.radiusL : Tokens.radiusM
        color: root.grouped && !root.hovered && !root.visualFocus && root.severity === 0 ? "transparent" : root.prominent ? Tokens.primary : root.severity === 2 ? Qt.tint(Tokens.surface, Qt.rgba(Tokens.error.r, Tokens.error.g, Tokens.error.b, 0.14)) : root.active || root.hovered ? Tokens.primaryContainer : Tokens.surface
        opacity: root.unavailable ? Tokens.surfaceOpacityLow : Tokens.transparencyEnabled ? Tokens.surfaceOpacityMedium : 1
        border.width: root.visualFocus || root.severity === 2 ? Tokens.space2 : root.grouped ? 0 : Tokens.capsuleBorderWidth
        border.color: root.visualFocus || root.severity > 0 ? root.ink : Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
        Behavior on radius {
            NumberAnimation {
                duration: Tokens.springSpatialMicro.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springSpatialMicro.curve
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
        }
    }
}
