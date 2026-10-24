// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "statusDashboard"
    heading: I18n.t("lab.dashboard.title")
    subtitle: I18n.t("lab.preview")
    signal customizeRequested
    Flow {
        Layout.fillWidth: true
        spacing: Tokens.rowGap
        Repeater {
            model: Shell.ribbon.modules
            delegate: StatusModule {
                required property var modelData
                module: modelData
                detailed: true
                visible: module.id !== "workspaces" && (module.id !== "battery" || Shell.state.snapshot.capabilities.battery)
                onInvoked: moduleId => Shell.showNotice(I18n.t(module.titleId) + ": " + valueText)
            }
        }
    }
    ActionButton {
        text: I18n.t("lab.ribbon.customize")
        Layout.fillWidth: true
        onClicked: root.customizeRequested()
    }
}
