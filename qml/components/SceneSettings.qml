// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "sceneSettings"
    modal: true
    width: Tokens.settingsWidth
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
                        text: qsTr("Make room for your rhythm.")
                        font: Tokens.title
                        color: Tokens.textPrimary
                    }
                    Label {
                        text: qsTr("Scene preferences · this preview session")
                        font: Tokens.caption
                        color: Tokens.textSecondary
                    }
                }
                IconButton {
                    iconName: "close"
                    text: qsTr("Close preferences")
                    onClicked: root.close()
                }
            }
            ComboBox {
                Layout.fillWidth: true
                model: Shell.scenes.scenes
                textRole: "name"
                valueRole: "id"
                currentIndex: Shell.scenes.activeId === "performance" ? 0 : Shell.scenes.activeId === "balanced" ? 1 : 2
                Accessible.name: qsTr("Scene to customize")
                onActivated: Shell.scenes.select(currentValue)
            }
            Label {
                text: qsTr("Visual policy is applied here. System power policy remains mock. Unsupported CPU, GPU and display controls are hidden.")
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
                    text: qsTr("Theme")
                    color: Tokens.textPrimary
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: [qsTr("Auto"), qsTr("Light"), qsTr("Dark")]
                    currentIndex: ["auto", "light", "dark"].indexOf(Shell.scenes.current.visual.theme)
                    Accessible.name: qsTr("Scene theme")
                    onActivated: Shell.scenes.customize("theme", ["auto", "light", "dark"][currentIndex])
                }
                Label {
                    text: qsTr("Blur quality")
                    color: Tokens.textPrimary
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: [qsTr("Low"), qsTr("Medium"), qsTr("High")]
                    currentIndex: Shell.scenes.current.visual.blurQuality - 1
                    Accessible.name: qsTr("Scene blur quality")
                    onActivated: Shell.scenes.customize("blurQuality", currentIndex + 1)
                }
                Label {
                    text: qsTr("Motion")
                    color: Tokens.textPrimary
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: [qsTr("Reduced"), qsTr("Normal"), qsTr("Expressive")]
                    currentIndex: Shell.scenes.current.visual.motion
                    Accessible.name: qsTr("Scene motion")
                    onActivated: Shell.scenes.customize("motion", currentIndex)
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: Tokens.space8
                Switch {
                    text: qsTr("Blur")
                    checked: Shell.scenes.current.visual.blurEnabled
                    onToggled: Shell.scenes.customize("blurEnabled", checked)
                }
                Switch {
                    text: qsTr("Transparency")
                    checked: Shell.scenes.current.visual.transparency
                    onToggled: Shell.scenes.customize("transparency", checked)
                }
                Switch {
                    text: qsTr("Shadows")
                    checked: Shell.scenes.current.visual.shadows
                    onToggled: Shell.scenes.customize("shadows", checked)
                }
            }
            Label {
                text: qsTr("Accent")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            RowLayout {
                Button {
                    text: qsTr("Auto")
                    onClicked: Tokens.accentChoice = "auto"
                }
                Button {
                    text: qsTr("Teal")
                    onClicked: Tokens.accentChoice = "teal"
                }
                Button {
                    text: qsTr("Lilac")
                    onClicked: Tokens.accentChoice = "lilac"
                }
                Button {
                    text: qsTr("Apricot")
                    onClicked: Tokens.accentChoice = "apricot"
                }
            }
            Button {
                text: qsTr("Reset this scene")
                onClicked: Shell.scenes.resetCurrent()
            }
            Label {
                text: qsTr("Application shortcuts")
                font: Tokens.title
                color: Tokens.textPrimary
            }
            Label {
                text: qsTr("Edit and press Enter or leave the field. Changes last for this session; global Super shortcuts need compositor integration.")
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
                        text: shortcutRow.modelData.label
                        color: Tokens.textPrimary
                        Layout.fillWidth: true
                    }
                    TextField {
                        Layout.preferredWidth: Tokens.panelWidth / 2
                        text: shortcutRow.modelData.sequence
                        Accessible.name: qsTr("Shortcut for %1").arg(shortcutRow.modelData.label)
                        onEditingFinished: Shell.shortcuts.rebind(shortcutRow.modelData.id, text)
                    }
                }
            }
            Label {
                text: Shell.shortcuts.lastError
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Tokens.error
                visible: text.length > 0
            }
            Button {
                text: qsTr("Reset shortcuts")
                onClicked: Shell.shortcuts.resetDefaults()
            }
        }
    }
}
