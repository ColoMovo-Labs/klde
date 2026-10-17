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
    signal viewRequested(string view)
    property bool expanded: false
    readonly property var state: Shell.state.snapshot
    width: Math.min(Tokens.panelWidth + (expanded ? Tokens.space32 : 0), parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    height: Math.min(settingsColumn.implicitHeight + padding * 2, parent ? parent.height - y - Tokens.space24 : Tokens.previewHeight)
    contentItem: ScrollView {
        id: scroller
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            id: settingsColumn
            width: scroller.availableWidth
            spacing: Tokens.rowGap
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
            ActionButton {
                text: I18n.t(root.expanded ? "lab.quick.compact" : "lab.quick.expand")
                Layout.fillWidth: true
                onClicked: root.expanded = !root.expanded
            }
            GridLayout {
                columns: 2
                columnSpacing: Tokens.space12
                rowSpacing: Tokens.space12
                Layout.fillWidth: true
                ToggleTile {
                    text: I18n.t("shell.network.wifi")
                    iconName: "wifi"
                    detail: root.state.network.connected ? root.state.network.ssid : I18n.t("lab.network.offline")
                    selected: root.state.network.enabled
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.wifi = !Shell.system.wifi
                }
                ToggleTile {
                    text: I18n.t("shell.network.bluetooth")
                    iconName: "bluetooth"
                    enabled: root.state.capabilities.bluetooth
                    detail: !enabled ? I18n.t("lab.unavailable") : I18n.t(root.state.bluetooth.enabled ? "common.on" : "common.off")
                    selected: root.state.bluetooth.enabled
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
                visible: root.state.capabilities.brightness
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
            StateSlider {
                visible: root.expanded && root.state.capabilities.microphone
                path: "audio.microphone"
                label: I18n.t("lab.module.microphone")
                iconName: "microphone"
            }
            StateChoice {
                visible: root.expanded
                label: I18n.t("lab.audio.output")
                path: "audio.output"
                values: ["speakers", "headphones", "bluetooth"]
                labels: [I18n.t("lab.audio.speakers"), I18n.t("lab.audio.headphones"), I18n.t("shell.network.bluetooth")]
            }
            Switch {
                text: I18n.t("lab.dnd")
                checked: root.state.notifications.dnd
                onToggled: Shell.state.requestValue("notifications.dnd", checked)
            }
            Flow {
                visible: root.expanded
                Layout.fillWidth: true
                spacing: Tokens.space8
                ActionButton {
                    text: I18n.t("language.title")
                    onClicked: root.viewRequested("language")
                }
                ActionButton {
                    text: I18n.t("lab.center.title")
                    onClicked: root.viewRequested("notifications")
                }
                ActionButton {
                    text: I18n.t("lab.ribbon.customize")
                    onClicked: root.viewRequested("ribbon-settings")
                }
            }
            ChoiceBox {
                visible: root.expanded
                Layout.fillWidth: true
                model: [I18n.t("lab.density.comfortable"), I18n.t("lab.density.balanced"), I18n.t("lab.density.dense")]
                currentIndex: Tokens.densityMode
                Accessible.name: I18n.t("lab.density")
                onActivated: Shell.scenes.customize("density", currentIndex)
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
