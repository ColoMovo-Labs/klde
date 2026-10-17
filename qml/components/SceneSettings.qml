// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
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
            GridLayout {
                columns: 2
                columnSpacing: Tokens.space16
                rowSpacing: Tokens.space12
                Layout.fillWidth: true
                Label {
                    text: I18n.t("shell.effects.theme")
                    color: Tokens.textPrimary
                }
                ChoiceBox {
                    Layout.fillWidth: true
                    model: [I18n.t("common.auto"), I18n.t("common.light"), I18n.t("common.dark")]
                    currentIndex: ["auto", "light", "dark"].indexOf(Shell.scenes.current.visual.theme)
                    Accessible.name: I18n.t("shell.scene.theme.accessible")
                    onActivated: Shell.scenes.customize("theme", ["auto", "light", "dark"][currentIndex])
                }
                Label {
                    text: I18n.t("shell.scene.blur")
                    color: Tokens.textPrimary
                }
                ChoiceBox {
                    Layout.fillWidth: true
                    model: [I18n.t("common.low"), I18n.t("common.medium"), I18n.t("common.high")]
                    currentIndex: Shell.scenes.current.visual.blurQuality - 1
                    Accessible.name: I18n.t("shell.scene.blur.accessible")
                    onActivated: Shell.scenes.customize("blurQuality", currentIndex + 1)
                }
                Label {
                    text: I18n.t("shell.effects.motion")
                    color: Tokens.textPrimary
                }
                ChoiceBox {
                    Layout.fillWidth: true
                    model: [I18n.t("common.reduced"), I18n.t("common.normal"), I18n.t("common.expressive"), I18n.t("lab.motion.fast")]
                    currentIndex: Shell.scenes.current.visual.motion
                    Accessible.name: I18n.t("shell.scene.motion.accessible")
                    onActivated: Shell.scenes.customize("motion", currentIndex)
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
                Switch {
                    text: I18n.t("shell.effects.transparency")
                    checked: Shell.scenes.current.visual.transparency
                    onToggled: Shell.scenes.customize("transparency", checked)
                }
                Switch {
                    text: I18n.t("shell.effects.shadows")
                    checked: Shell.scenes.current.visual.shadows
                    onToggled: Shell.scenes.customize("shadows", checked)
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
