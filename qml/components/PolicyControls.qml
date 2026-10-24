// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
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
        visible: root.caps.cpuPolicy
        label: I18n.t("lab.policy.cpu")
        path: "policy.cpu"
        values: ["efficient", "balanced", "performance"]
        labels: [I18n.t("lab.policy.efficient"), I18n.t("lab.scene.balanced"), I18n.t("lab.scene.performance")]
    }
    StateSlider {
        visible: root.caps.cpuPolicy
        path: "policy.frequency"
        label: I18n.t("lab.policy.frequency")
        iconName: "cpu"
    }
    StateChoice {
        visible: root.caps.gpuPolicy
        label: I18n.t("lab.policy.gpu")
        path: "policy.gpu"
        values: root.caps.discreteGpu ? ["integrated", "hybrid", "discrete"] : ["integrated"]
        labels: root.caps.discreteGpu ? [I18n.t("lab.gpu.integrated"), I18n.t("lab.gpu.hybrid"), I18n.t("lab.gpu.discrete")] : [I18n.t("lab.gpu.integrated")]
    }
    Label {
        visible: root.caps.discreteGpu
        text: I18n.t("lab.policy.discrete-state").arg(I18n.t(Shell.state.snapshot.policy.discreteEnabled ? "common.on" : "common.off"))
        font: Tokens.caption
        color: Tokens.textSecondary
    }
    StateChoice {
        visible: root.caps.refreshRate
        label: I18n.t("lab.policy.refresh")
        path: "policy.refreshRate"
        values: [60, 90, 120, 144]
        labels: ["60 Hz", "90 Hz", "120 Hz", "144 Hz"]
    }
    StateChoice {
        visible: root.caps.brightness
        label: I18n.t("lab.policy.brightness")
        path: "policy.brightness"
        values: ["manual", "adaptive", "dim"]
        labels: [I18n.t("lab.brightness.manual"), I18n.t("lab.brightness.adaptive"), I18n.t("lab.brightness.dim")]
    }
}
