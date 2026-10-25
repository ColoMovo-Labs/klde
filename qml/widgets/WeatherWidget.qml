// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
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

    WeatherForm {
        anchors.fill: parent
        iconName: root.weather.available && root.weather.conditionId !== "weather.condition.unknown" ? "weather-" + root.weather.conditionId.split(".").pop() : "weather"
        temperatureText: root.weather.available ? root.weather.temperature + "°" : "—"
        locationText: root.weather.location
        conditionLabel: root.conditionLabel
        sourceText: I18n.s(root.weather.sourceLabel) + (root.weather.stale ? I18n.t("shell.weather.stale") : "")
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
