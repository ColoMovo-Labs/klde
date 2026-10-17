// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    required property string label
    required property string path
    required property var values
    required property var labels
    readonly property var snapshot: Shell.state.snapshot
    Layout.fillWidth: true
    spacing: Tokens.space4
    Label {
        text: root.label
        font: Tokens.label
        color: Tokens.textPrimary
    }
    ChoiceBox {
        Layout.fillWidth: true
        model: root.labels
        currentIndex: {
            const revision = root.snapshot;
            return root.values.indexOf(Shell.state.value(root.path));
        }
        Accessible.name: root.label
        onActivated: Shell.state.requestValue(root.path, root.values[currentIndex])
    }
}
