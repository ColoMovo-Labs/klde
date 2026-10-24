// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "candidatePreview"
    heading: I18n.t("lab.candidate.title")
    subtitle: I18n.t("lab.candidate.disclosure")
    width: Math.min(Tokens.panelWidth, parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    property int selectedIndex: 0
    function focusCandidate(index: int): void {
        const candidate = candidateRepeater.itemAt(index);
        if (candidate)
            candidate.forceActiveFocus();
    }
    onOpened: focusCandidate(0)
    readonly property bool simplified: Shell.state.snapshot.input.simplified
    Label {
        text: "nǐ hǎo"
        font: Tokens.headline
        color: Tokens.primary
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space4
        Repeater {
            id: candidateRepeater
            model: root.simplified ? ["你好", "你好吗", "你好呀"] : ["你好", "你好嗎", "你好呀"]
            delegate: ActionButton {
                required property int index
                required property string modelData
                objectName: "candidate" + index
                Layout.fillWidth: true
                emphasized: root.selectedIndex === index
                text: (index + 1).toString() + "   " + modelData
                onClicked: root.selectedIndex = index
                Keys.onRightPressed: root.focusCandidate((index + 1) % 3)
                Keys.onLeftPressed: root.focusCandidate((index + 2) % 3)
                Keys.onDownPressed: root.focusCandidate((index + 1) % 3)
                Keys.onUpPressed: root.focusCandidate((index + 2) % 3)
            }
        }
    }
    Switch {
        text: I18n.t("lab.input.simplified")
        checked: root.simplified
        onToggled: Shell.state.requestValue("input.simplified", checked)
    }
    Label {
        text: I18n.t("lab.candidate.selected").arg(root.selectedIndex + 1)
        font: Tokens.caption
        color: Tokens.textSecondary
    }
}
