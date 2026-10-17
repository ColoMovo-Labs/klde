// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "ribbonSettings"
    heading: I18n.t("lab.ribbon.customize")
    subtitle: I18n.t("lab.ribbon.temporary")
    Switch {
        text: I18n.t("lab.ribbon.enable")
        checked: Shell.ribbon.enabled
        onToggled: Shell.ribbon.enabled = checked
    }
    Switch {
        text: I18n.t("lab.ribbon.compact")
        checked: Shell.ribbon.compact
        onToggled: Shell.ribbon.compact = checked
    }
    Label {
        text: I18n.t("lab.density")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: [I18n.t("lab.density.comfortable"), I18n.t("lab.density.balanced"), I18n.t("lab.density.dense")]
        currentIndex: Tokens.densityMode
        onActivated: Shell.scenes.customize("density", currentIndex)
    }
    Label {
        text: I18n.t("lab.ribbon.margin")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    Slider {
        Layout.fillWidth: true
        from: 4
        to: 40
        stepSize: 1
        value: Shell.ribbon.margin
        Accessible.name: I18n.t("lab.ribbon.margin")
        onMoved: Shell.ribbon.margin = Math.round(value)
    }
    Label {
        text: I18n.t("lab.ribbon.spacing")
        font: Tokens.label
        color: Tokens.textPrimary
    }
    Slider {
        Layout.fillWidth: true
        from: 2
        to: 16
        stepSize: 1
        value: Shell.ribbon.spacing
        Accessible.name: I18n.t("lab.ribbon.spacing")
        onMoved: Shell.ribbon.spacing = Math.round(value)
    }
    Label {
        text: I18n.t("lab.ribbon.position")
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Repeater {
        model: Shell.ribbon.modules
        delegate: ColumnLayout {
            id: moduleRow
            required property var modelData
            Layout.fillWidth: true
            RowLayout {
                Layout.fillWidth: true
                Switch {
                    text: I18n.t(moduleRow.modelData.titleId)
                    enabled: moduleRow.modelData.id !== "time"
                    checked: moduleRow.modelData.enabled
                    Layout.fillWidth: true
                    onToggled: Shell.ribbon.setVisible(moduleRow.modelData.id, checked)
                }
                IconButton {
                    iconName: "previous"
                    text: I18n.t("lab.ribbon.earlier")
                    onClicked: Shell.ribbon.move(moduleRow.modelData.id, -1)
                }
                IconButton {
                    iconName: "next"
                    text: I18n.t("lab.ribbon.later")
                    onClicked: Shell.ribbon.move(moduleRow.modelData.id, 1)
                }
            }
            ChoiceBox {
                Layout.fillWidth: true
                model: moduleRow.modelData.id === "time" ? [I18n.t("lab.ribbon.center")] : [I18n.t("lab.ribbon.left"), I18n.t("lab.ribbon.right")]
                enabled: moduleRow.modelData.id !== "time"
                currentIndex: moduleRow.modelData.id === "time" ? 0 : moduleRow.modelData.section === 0 ? 0 : 1
                Accessible.name: I18n.t(moduleRow.modelData.titleId)
                onActivated: Shell.ribbon.setSection(moduleRow.modelData.id, currentIndex === 0 ? 0 : 2)
            }
        }
    }
    ActionButton {
        text: I18n.t("lab.ribbon.reset")
        onClicked: Shell.ribbon.reset()
    }
}
