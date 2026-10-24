// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "sceneSettings"
    signal languageInputRequested
    modal: true
    width: Math.min(Tokens.settingsWidth, parent ? parent.width - Tokens.space32 : Tokens.settingsWidth)
    height: Math.min(Tokens.settingsHeight, parent ? parent.height - Tokens.space32 * 2 : Tokens.settingsHeight)
    contentItem: ScrollView {
        id: scroll
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            width: scroll.availableWidth
            spacing: Tokens.space16
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: I18n.t("shell.scene.title")
                        font: Tokens.title
                        color: Tokens.textPrimary
                    }
                    Label {
                        text: I18n.t("shell.scene.subtitle")
                        font: Tokens.caption
                        color: Tokens.textSecondary
                    }
                }
                IconButton {
                    iconName: "close"
                    text: I18n.t("shell.scene.close")
                    onClicked: root.close()
                }
            }
            ChoiceBox {
                Layout.fillWidth: true
                model: [I18n.t("shell.scene.performance"), I18n.t("shell.scene.balanced"), I18n.t("shell.scene.saver")]
                currentIndex: Shell.scenes.activeId === "performance" ? 0 : Shell.scenes.activeId === "balanced" ? 1 : 2
                Accessible.name: I18n.t("shell.scene.select")
                onActivated: Shell.scenes.select(["performance", "balanced", "power-saver"][currentIndex])
            }
            ActionButton {
                text: I18n.t("language.title")
                Layout.fillWidth: true
                onClicked: root.languageInputRequested()
            }
            Label {
                text: I18n.t("shell.scene.disclosure")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font: Tokens.caption
                color: Tokens.textSecondary
            }
            SettingsForm {
                id: settingsForm
                Layout.fillWidth: true
                themeText: I18n.t("shell.effects.theme")
                wallpaperText: I18n.t("wallpaper.title")
                motionText: I18n.t("shell.effects.motion")
                densityText: I18n.t("lab.density")
                transparencyText: I18n.t("shell.effects.transparency")
                shadowsText: I18n.t("shell.effects.shadows")
                themeChoice.model: [I18n.t("common.light"), I18n.t("common.dark"), I18n.t("common.auto")]
                themeChoice.currentIndex: ["light", "dark", "auto"].indexOf(Shell.scenes.current.visual.theme)
                wallpaperChoice.currentIndex: ["snow", "abstract", "quiet", "kemono"].indexOf(Tokens.wallpaperChoice)
                motionChoice.model: [I18n.t("common.reduced"), I18n.t("common.normal"), I18n.t("common.expressive"), I18n.t("lab.motion.fast")]
                motionChoice.currentIndex: Shell.scenes.current.visual.motion
                densityChoice.model: [I18n.t("lab.density.comfortable"), I18n.t("lab.density.balanced"), I18n.t("lab.density.dense")]
                densityChoice.currentIndex: Tokens.densityMode
                transparencySwitch.checked: Shell.scenes.current.visual.transparency
                shadowsSwitch.checked: Shell.scenes.current.visual.shadows
                Connections {
                    target: settingsForm.themeChoice
                    function onActivated(index: int): void {
                        Shell.scenes.customize("theme", ["light", "dark", "auto"][index]);
                    }
                }
                Connections {
                    target: settingsForm.wallpaperChoice
                    function onActivated(index: int): void {
                        Shell.state.requestValue("appearance.wallpaper", ["snow", "abstract", "quiet", "kemono"][index]);
                    }
                }
                Connections {
                    target: settingsForm.motionChoice
                    function onActivated(index: int): void {
                        Shell.scenes.customize("motion", index);
                    }
                }
                Connections {
                    target: settingsForm.densityChoice
                    function onActivated(index: int): void {
                        Shell.scenes.customize("density", index);
                    }
                }
                Connections {
                    target: settingsForm.transparencySwitch
                    function onToggled(): void {
                        Shell.scenes.customize("transparency", settingsForm.transparencySwitch.checked);
                    }
                }
                Connections {
                    target: settingsForm.shadowsSwitch
                    function onToggled(): void {
                        Shell.scenes.customize("shadows", settingsForm.shadowsSwitch.checked);
                    }
                }
                Connections {
                    target: settingsForm.languageButton
                    function onClicked(): void {
                        root.languageInputRequested();
                    }
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: Tokens.space8
                Switch {
                    text: I18n.t("shell.effects.blur")
                    checked: Shell.scenes.current.visual.blurEnabled
                    onToggled: Shell.scenes.customize("blurEnabled", checked)
                }
                ChoiceBox {
                    model: [I18n.t("common.low"), I18n.t("common.medium"), I18n.t("common.high")]
                    currentIndex: Shell.scenes.current.visual.blurQuality - 1
                    Accessible.name: I18n.t("shell.scene.blur.accessible")
                    onActivated: Shell.scenes.customize("blurQuality", currentIndex + 1)
                }
            }
            Label {
                text: I18n.t("shell.effects.accent")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            RowLayout {
                ActionButton {
                    text: I18n.t("common.auto")
                    onClicked: Tokens.accentChoice = "auto"
                }
                ActionButton {
                    text: I18n.t("shell.effects.teal")
                    onClicked: Tokens.accentChoice = "teal"
                }
                ActionButton {
                    text: I18n.t("shell.effects.lilac")
                    onClicked: Tokens.accentChoice = "lilac"
                }
                ActionButton {
                    text: I18n.t("shell.effects.apricot")
                    onClicked: Tokens.accentChoice = "apricot"
                }
            }
            ActionButton {
                text: I18n.t("shell.scene.reset")
                onClicked: Shell.scenes.resetCurrent()
            }
            PolicyControls {
                Layout.fillWidth: true
            }
            Label {
                text: I18n.t("shell.shortcut.title")
                font: Tokens.title
                color: Tokens.textPrimary
            }
            Label {
                text: I18n.t("shell.shortcut.help")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font: Tokens.caption
                color: Tokens.textSecondary
            }
            Repeater {
                model: Shell.shortcuts.actions
                delegate: RowLayout {
                    id: shortcutRow
                    required property var modelData
                    Layout.fillWidth: true
                    Label {
                        text: I18n.s(shortcutRow.modelData.label)
                        color: Tokens.textPrimary
                        Layout.fillWidth: true
                    }
                    TextField {
                        Layout.preferredWidth: Tokens.panelWidth / 2
                        text: shortcutRow.modelData.sequence
                        Accessible.name: I18n.t("shell.shortcut.field").arg(I18n.s(shortcutRow.modelData.label))
                        onEditingFinished: Shell.shortcuts.rebind(shortcutRow.modelData.id, text)
                    }
                }
            }
            Label {
                text: I18n.s(Shell.shortcuts.lastError)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Tokens.error
                visible: text.length > 0
            }
            ActionButton {
                text: I18n.t("shell.shortcut.reset")
                onClicked: Shell.shortcuts.resetDefaults()
            }
        }
    }
}
