// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.weatherWidgetSize
    height: Tokens.weatherWidgetSize
    property string iconName: "weather-partly-cloudy"
    property string temperatureText: "21°"
    property string locationText: "Snowline"
    property string conditionLabel: "晴间多云"
    property string sourceText: "模拟天气"
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.space4
        Glyph {
            name: root.iconName
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tokens.weatherIcon
            Layout.preferredHeight: Tokens.weatherIcon
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.temperatureText
            font: Tokens.weatherTemperature
            color: Tokens.secondary
            Accessible.name: root.temperatureText + " " + root.conditionLabel
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.locationText
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.weatherWidgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.label
            color: Tokens.textPrimary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.conditionLabel
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.weatherWidgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.caption
            color: Tokens.textSecondary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.sourceText
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.weatherWidgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.caption
            color: Tokens.textSecondary
        }
    }
}
