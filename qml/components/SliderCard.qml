// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property string label
    required property string iconName
    property int value: 0
    signal valueRequested(int requestedValue)
    spacing: Tokens.space4
    RowLayout {
        Layout.fillWidth: true
        Icon {
            name: root.iconName
            width: Tokens.iconS
            height: Tokens.iconS
        }
        Label {
            text: root.label
            font: Tokens.label
            color: Tokens.textPrimary
            Layout.fillWidth: true
        }
        Label {
            text: root.value + "%"
            font: Tokens.caption
            color: Tokens.textSecondary
        }
    }
    Slider {
        Layout.fillWidth: true
        from: 0
        to: 100
        stepSize: 1
        value: root.value
        Accessible.name: root.label
        onMoved: root.valueRequested(Math.round(value))
    }
}
