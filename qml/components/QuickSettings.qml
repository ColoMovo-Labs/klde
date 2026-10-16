// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "quickSettings"
    signal blurRequested
    signal sceneSettingsRequested
    width: Tokens.panelWidth
    height: Math.min(settingsColumn.implicitHeight + padding * 2, parent ? parent.height - y - Tokens.space24 : Tokens.previewHeight)
    contentItem: ScrollView {
        id: scroller
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            id: settingsColumn
            width: scroller.availableWidth
            spacing: Tokens.space16
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.space4
                    Label {
                        text: I18n.t("shell.quick.title")
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font: Tokens.title
                        color: Tokens.textPrimary
                    }
                    Label {
                        text: I18n.t("shell.quick.provenance")
                        font: Tokens.caption
                        color: Tokens.textSecondary
                    }
                }
                IconButton {
                    iconName: "close"
                    text: I18n.t("shell.quick.close")
                    onClicked: root.close()
                }
            }
            GridLayout {
                columns: 2
                columnSpacing: Tokens.space12
                rowSpacing: Tokens.space12
                Layout.fillWidth: true
                ToggleTile {
                    text: I18n.t("shell.network.wifi")
                    iconName: "wifi"
                    selected: Shell.system.wifi
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.wifi = !Shell.system.wifi
                }
                ToggleTile {
                    text: I18n.t("shell.network.bluetooth")
                    iconName: "bluetooth"
                    selected: Shell.system.bluetooth
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.bluetooth = !Shell.system.bluetooth
                }
                ToggleTile {
                    text: I18n.t("shell.effects.night")
                    iconName: "moon"
                    selected: Shell.system.nightMode
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.nightMode = !Shell.system.nightMode
                }
                ToggleTile {
                    text: I18n.t("shell.effects.quiet")
                    iconName: "leaf"
                    selected: Shell.scenes.current.visual.motion === 0
                    Layout.fillWidth: true
                    onToggleRequested: Shell.scenes.customize("motion", Tokens.reducedMotion ? 1 : 0)
                }
            }
            SliderCard {
                label: I18n.t("shell.effects.brightness")
                iconName: "sun"
                value: Shell.system.brightness
                Layout.fillWidth: true
                onValueRequested: requestedValue => Shell.system.brightness = requestedValue
            }
            SliderCard {
                label: I18n.t("shell.effects.volume")
                iconName: "volume"
                value: Shell.system.volume
                Layout.fillWidth: true
                onValueRequested: requestedValue => Shell.system.volume = requestedValue
            }
            PowerSceneCard {
                Layout.fillWidth: true
                onCustomizeRequested: {
                    root.close();
                    root.sceneSettingsRequested();
                }
            }
            RowLayout {
                Layout.fillWidth: true
                ActionButton {
                    text: I18n.t("shell.blur.open")
                    font: Tokens.label
                    onClicked: {
                        root.close();
                        root.blurRequested();
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                IconButton {
                    iconName: "settings"
                    text: I18n.t("shell.settings.open")
                    onClicked: {
                        root.close();
                        root.sceneSettingsRequested();
                    }
                }
                IconButton {
                    iconName: "power"
                    text: I18n.t("destructive.session.preview")
                    onClicked: Shell.system.requestSessionAction("shutdown")
                }
            }
        }
    }
}
