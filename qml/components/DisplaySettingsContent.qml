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
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space8
        visible: Shell.state.snapshot.capabilities.brightness
        SliderCard {
            Layout.fillWidth: true
            label: I18n.t("shell.effects.brightness")
            iconName: "sun"
            value: Shell.system.brightness
            onValueRequested: requestedValue => Shell.system.brightness = requestedValue
        }
        MockBadge {
            path: "brightness"
        }
    }
    Switch {
        text: I18n.t("shell.effects.night")
        checked: Shell.system.nightMode
        onToggled: Shell.system.nightMode = checked
    }
    Switch {
        objectName: "settingsRibbonAllScreens"
        text: I18n.t("settings.displays.ribbon-all")
        checked: Shell.settings.values["ribbon.allScreens"] === true
        onToggled: Shell.settings.setValue("ribbon.allScreens", checked)
    }
    Switch {
        objectName: "settingsDockAllScreens"
        text: I18n.t("settings.displays.dock-all")
        checked: Shell.settings.values["dock.allScreens"] === true
        onToggled: Shell.settings.setValue("dock.allScreens", checked)
    }
    Label {
        text: I18n.t("settings.displays.readonly")
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Repeater {
        objectName: "settingsScreens"
        model: Shell.screens
        delegate: Rectangle {
            id: screenCard
            required property string name
            required property bool primary
            required property rect geometry
            required property real pixelRatio
            required property real refreshRate
            required property string manufacturer
            required property string modelName
            objectName: "settingsScreen-" + name
            Layout.fillWidth: true
            implicitHeight: screenColumn.implicitHeight + Tokens.space32
            radius: Tokens.radiusXL
            color: screenCard.primary ? Tokens.primaryContainer : Tokens.surfaceContainer
            Accessible.role: Accessible.Grouping
            Accessible.name: screenCard.name
            ColumnLayout {
                id: screenColumn
                anchors.fill: parent
                anchors.margins: Tokens.space16
                spacing: Tokens.space4
                Label {
                    text: (screenCard.primary ? I18n.t("settings.displays.primary") + " · " : "") + screenCard.name + (screenCard.modelName.length > 0 ? " · " + screenCard.manufacturer + " " + screenCard.modelName : "")
                    font: Tokens.label
                    color: Tokens.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    text: I18n.t("settings.displays.mode").arg(Math.round(screenCard.geometry.width * screenCard.pixelRatio)).arg(Math.round(screenCard.geometry.height * screenCard.pixelRatio)).arg(I18n.number(screenCard.refreshRate, 0)).arg(I18n.number(screenCard.pixelRatio * 100, 0))
                    font: Tokens.body
                    color: Tokens.textPrimary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    text: I18n.t("settings.displays.geometry").arg(screenCard.geometry.width).arg(screenCard.geometry.height).arg(screenCard.geometry.x).arg(screenCard.geometry.y)
                    font: Tokens.caption
                    color: Tokens.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
