// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string iconName: "wifi"
    property string detail: checked ? I18n.t("common.on") : I18n.t("common.off")
    property bool selected: false
    signal toggleRequested
    checkable: true
    checked: selected
    scale: root.down ? Tokens.pressScale : root.hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    implicitHeight: Tokens.toggleHeight
    leftPadding: Tokens.space12
    rightPadding: Tokens.space12
    Accessible.name: text + ", " + detail
    onClicked: toggleRequested()
    contentItem: RowLayout {
        spacing: Tokens.space8
        Rectangle {
            Layout.preferredWidth: Tokens.toggleIcon
            Layout.preferredHeight: Tokens.toggleIcon
            radius: root.checked ? Tokens.radiusPill : Tokens.radiusM
            color: root.checked ? Tokens.primary : Tokens.surfaceElevated
            Icon {
                anchors.centerIn: parent
                name: root.iconName
                lightInk: root.checked ? !Tokens.darkMode : Tokens.darkMode
                width: Tokens.iconM
                height: Tokens.iconM
            }
            Behavior on radius {
                NumberAnimation {
                    duration: Tokens.springSpatialMicro.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.springSpatialMicro.curve
                }
            }
        }
        ColumnLayout {
            spacing: Tokens.space2
            Text {
                Layout.fillWidth: true
                text: root.text
                font: Tokens.label
                color: Tokens.textPrimary
                wrapMode: Text.WordWrap
            }
            Text {
                text: root.detail
                font: Tokens.caption
                color: Tokens.textSecondary
            }
        }
    }
    background: Rectangle {
        radius: root.checked ? Tokens.radiusXL : Tokens.radiusM
        color: root.checked || root.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
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
