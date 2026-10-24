// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Surface {
    id: root
    required property var weather
    readonly property string conditionLabel: weather.available ? I18n.t(weather.conditionId) : I18n.t("friendly.weather.unavailable")
    signal settingsRequested
    width: Tokens.weatherWidgetSize
    height: Tokens.weatherWidgetSize
    cornerRadius: Tokens.weatherWidgetSize / 2
    padding: Tokens.weatherWidgetPadding
    tone: Tokens.surfaceContainerHigh

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.space4
        Icon {
            name: root.weather.available && root.weather.conditionId !== "weather.condition.unknown" ? "weather-" + root.weather.conditionId.split(".").pop() : "weather"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Tokens.weatherIcon
            Layout.preferredHeight: Tokens.weatherIcon
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.available ? root.weather.temperature + "°" : "—"
            font: Tokens.weatherTemperature
            color: Tokens.secondary
            Accessible.name: root.weather.available ? I18n.t("shell.weather.degrees").arg(root.weather.temperature).arg(root.conditionLabel) : I18n.t("friendly.weather.unavailable")
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.location
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
            text: I18n.s(root.weather.sourceLabel) + (root.weather.stale ? I18n.t("shell.weather.stale") : "")
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.weatherWidgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.caption
            color: Tokens.textSecondary
        }
    }
    TapHandler {
        onTapped: root.settingsRequested()
    }
    Keys.onReturnPressed: settingsRequested()
    Keys.onSpacePressed: settingsRequested()
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: I18n.t("shell.weather.settings").arg(root.weather.sourceLabel)
    Accessible.onPressAction: settingsRequested()
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: root.cornerRadius
        border.width: root.activeFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
}
