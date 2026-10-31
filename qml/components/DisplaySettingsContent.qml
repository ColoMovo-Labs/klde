// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    spacing: Tokens.space16
    SliderCard {
        Layout.fillWidth: true
        label: I18n.t("shell.effects.brightness")
        iconName: "sun"
        value: Shell.system.brightness
        visible: Shell.state.snapshot.capabilities.brightness
        onValueRequested: requestedValue => Shell.system.brightness = requestedValue
    }
    Switch {
        text: I18n.t("shell.effects.night")
        checked: Shell.system.nightMode
        onToggled: Shell.system.nightMode = checked
    }
    Label {
        text: I18n.t("settings.displays.readonly")
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Repeater {
        model: Qt.application.screens
        delegate: Rectangle {
            id: screenCard
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: screenColumn.implicitHeight + Tokens.space32
            radius: Tokens.radiusXL
            color: Tokens.surfaceContainer
            ColumnLayout {
                id: screenColumn
                anchors.fill: parent
                anchors.margins: Tokens.space16
                spacing: Tokens.space4
                Label {
                    text: screenCard.modelData.name + (screenCard.modelData.model.length > 0 ? " · " + screenCard.modelData.manufacturer + " " + screenCard.modelData.model : "")
                    font: Tokens.label
                    color: Tokens.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    text: I18n.t("settings.displays.geometry").arg(screenCard.modelData.width).arg(screenCard.modelData.height).arg(I18n.number(screenCard.modelData.devicePixelRatio * 100, 0)).arg(screenCard.modelData.virtualX).arg(screenCard.modelData.virtualY)
                    font: Tokens.body
                    color: Tokens.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
