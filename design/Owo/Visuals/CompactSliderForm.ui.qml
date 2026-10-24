// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Slider {
    id: root
    property string label: "Volume"
    property string glyph: "volume"
    implicitHeight: Tokens.compactSliderHeight
    from: 0
    to: 100
    stepSize: 1
    leftPadding: Tokens.space32 + Tokens.space8
    rightPadding: 0
    Accessible.name: label
    background: Item {
        Glyph {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            name: root.glyph
        }
        Rectangle {
            x: root.leftPadding
            width: root.availableWidth
            height: root.height
            radius: Tokens.radiusL
            color: Tokens.primaryContainer
            Rectangle {
                width: root.visualPosition * parent.width
                height: parent.height
                radius: Tokens.radiusL
                color: Tokens.primary
            }
            Text {
                x: Tokens.space12
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.value) + "%"
                font: Tokens.label
                color: Tokens.textPrimary
            }
            Item {
                width: root.visualPosition * parent.width
                height: parent.height
                clip: true
                Text {
                    x: Tokens.space12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.value) + "%"
                    font: Tokens.label
                    color: Tokens.textOnPrimary
                }
            }
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        anchors.verticalCenter: parent.verticalCenter
        width: Tokens.space4
        height: root.height - Tokens.space16
        radius: Tokens.radiusPill
        color: Tokens.textOnPrimary
        border.width: 1
        border.color: Tokens.primary
    }
}
