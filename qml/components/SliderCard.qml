// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    required property string label
    required property string iconName
    property int value: 0
    property string unit: "%"
    property int maximumValue: 100
    property int minimumValue: 0
    signal valueRequested(int requestedValue)
    spacing: Tokens.space12
    Icon {
        name: root.iconName
        Layout.preferredWidth: Tokens.iconM
        Layout.preferredHeight: Tokens.iconM
    }
    Slider {
        id: control
        Layout.fillWidth: true
        implicitHeight: Tokens.sliderHeight
        from: root.minimumValue
        to: root.maximumValue
        stepSize: 1
        value: root.value
        leftPadding: 0
        rightPadding: 0
        Accessible.name: root.label
        ToolTip.visible: hovered
        ToolTip.text: root.label
        onMoved: root.valueRequested(Math.round(value))
        background: Rectangle {
            x: control.leftPadding
            y: (control.height - height) / 2
            width: control.availableWidth
            height: Tokens.sliderHeight
            radius: Tokens.radiusL
            color: Tokens.primaryContainer
            border.width: control.visualFocus ? Tokens.space2 : 0
            border.color: Tokens.primary
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: control.visualPosition * parent.width
                radius: Tokens.radiusL
                color: Tokens.primary
            }
            Text {
                anchors.left: parent.left
                anchors.leftMargin: Tokens.space16
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.number(root.value, 0) + root.unit
                font: Tokens.label
                Accessible.ignored: true
                color: Tokens.textPrimary
            }
            Item {
                width: control.visualPosition * parent.width
                height: parent.height
                clip: true
                Text {
                    x: Tokens.space16
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.number(root.value, 0) + root.unit
                    font: Tokens.label
                    Accessible.ignored: true
                    color: Tokens.textOnPrimary
                }
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: (control.height - height) / 2
            width: control.pressed ? Tokens.space8 : Tokens.space4
            height: Tokens.space32
            radius: Tokens.radiusPill
            color: Tokens.textOnPrimary
            border.width: Tokens.space1
            border.color: Tokens.primary
        }
    }
}
