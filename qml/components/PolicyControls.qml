// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    readonly property var caps: Shell.state.snapshot.capabilities
    spacing: Tokens.rowGap
    Label {
        text: I18n.t("lab.policy.title")
        font: Tokens.title
        color: Tokens.textPrimary
    }
    Label {
        text: I18n.t("lab.policy.disclosure")
        font: Tokens.caption
        color: Tokens.textSecondary
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    StateChoice {
        visible: parent.caps.cpuPolicy
        label: I18n.t("lab.policy.cpu")
        path: "policy.cpu"
        values: ["efficient", "balanced", "performance"]
        labels: [I18n.t("lab.policy.efficient"), I18n.t("lab.scene.balanced"), I18n.t("lab.scene.performance")]
    }
    StateSlider {
        visible: parent.caps.cpuPolicy
        path: "policy.frequency"
        label: I18n.t("lab.policy.frequency")
        iconName: "cpu"
    }
    StateChoice {
        visible: parent.caps.gpuPolicy
        label: I18n.t("lab.policy.gpu")
        path: "policy.gpu"
        values: parent.caps.discreteGpu ? ["integrated", "hybrid", "discrete"] : ["integrated"]
        labels: parent.caps.discreteGpu ? [I18n.t("lab.gpu.integrated"), I18n.t("lab.gpu.hybrid"), I18n.t("lab.gpu.discrete")] : [I18n.t("lab.gpu.integrated")]
    }
    StateChoice {
        visible: parent.caps.refreshRate
        label: I18n.t("lab.policy.refresh")
        path: "policy.refreshRate"
        values: [60, 90, 120, 144]
        labels: ["60 Hz", "90 Hz", "120 Hz", "144 Hz"]
    }
    StateChoice {
        visible: parent.caps.brightness
        label: I18n.t("lab.policy.brightness")
        path: "policy.brightness"
        values: ["manual", "adaptive", "dim"]
        labels: [I18n.t("lab.brightness.manual"), I18n.t("lab.brightness.adaptive"), I18n.t("lab.brightness.dim")]
    }
}
