// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Surface {
    id: root
    required property var weather
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
            color: Tokens.textPrimary
            Accessible.name: root.weather.available ? qsTr("%1 degrees, %2").arg(root.weather.temperature).arg(root.weather.condition) : qsTr("Weather unavailable")
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
            text: root.weather.condition
            textFormat: Text.PlainText
            Layout.maximumWidth: Tokens.widgetSize - Tokens.space32
            elide: Text.ElideRight
            font: Tokens.caption
            color: Tokens.textSecondary
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.weather.sourceLabel + (root.weather.stale ? qsTr(" · stale") : "")
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
    Accessible.name: qsTr("Weather settings, %1").arg(root.weather.sourceLabel)
    Accessible.onPressAction: settingsRequested()
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: root.cornerRadius
        border.width: root.activeFocus ? Tokens.space2 : 0
        border.color: Tokens.primary
    }
}
