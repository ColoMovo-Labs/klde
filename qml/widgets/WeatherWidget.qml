// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Surface {
    id: root
    required property var weather
    readonly property string conditionLabel: weather.available ? I18n.t(weather.conditionId) : I18n.t("friendly.weather.unavailable")
    signal settingsRequested
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
            text: root.weather.available ? root.weather.temperature + "°" : "—"
            font: Tokens.display
            color: Tokens.primary
            Accessible.name: root.weather.available ? I18n.t("shell.weather.degrees").arg(root.weather.temperature).arg(root.conditionLabel) : I18n.t("friendly.weather.unavailable")
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.location
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.widgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.label
            color: Tokens.textPrimary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.conditionLabel
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.widgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.caption
            color: Tokens.textSecondary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: I18n.s(root.weather.sourceLabel) + (root.weather.stale ? I18n.t("shell.weather.stale") : "")
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.widgetSize - Tokens.space32
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
