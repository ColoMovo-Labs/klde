// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Surface {
    id: root
    required property var weather
    width: Tokens.widgetSize
    height: Tokens.widgetSize
    cornerRadius: Tokens.widgetSize / 2
    padding: Tokens.space24

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.space4
        Icon {
            name: "weather"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tokens.iconL
            Layout.preferredHeight: Tokens.iconL
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.temperature + "°"
            font: Tokens.display
            color: Tokens.textPrimary
            Accessible.name: qsTr("%1 degrees, %2").arg(root.weather.temperature).arg(root.weather.condition)
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.location
            font: Tokens.label
            color: Tokens.textPrimary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.condition
            font: Tokens.caption
            color: Tokens.textSecondary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.sourceLabel
            font: Tokens.caption
            color: Tokens.textDisabled
        }
    }
}
