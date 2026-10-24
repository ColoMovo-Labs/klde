// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals

StatusCapsuleForm {
    id: root
    unavailableText: I18n.t("lab.unavailable")
    scale: down ? Tokens.pressScale : hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    Canvas {
        id: ring
        parent: root.meterHost
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
}
