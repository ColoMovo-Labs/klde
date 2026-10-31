// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    signal languageInputRequested
    spacing: Tokens.space16
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
            emphasized: Tokens.accentChoice === "auto"
            onClicked: Shell.settings.setValue("appearance.accent", "auto")
        }
        ActionButton {
            text: I18n.t("shell.effects.teal")
            emphasized: Tokens.accentChoice === "teal"
            onClicked: Shell.settings.setValue("appearance.accent", "teal")
        }
        ActionButton {
            text: I18n.t("shell.effects.lilac")
            emphasized: Tokens.accentChoice === "lilac"
            onClicked: Shell.settings.setValue("appearance.accent", "lilac")
        }
        ActionButton {
            text: I18n.t("shell.effects.apricot")
            emphasized: Tokens.accentChoice === "apricot"
            onClicked: Shell.settings.setValue("appearance.accent", "apricot")
        }
    }
    ActionButton {
        text: I18n.t("shell.scene.reset")
        onClicked: Shell.scenes.resetCurrent()
    }
}
