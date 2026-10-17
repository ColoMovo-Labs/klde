// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import KLDE.Backends

Item {
    id: root
    signal action(string id)
    Instantiator {
        model: Shell.shortcuts.actions
        delegate: Shortcut {
            required property var modelData
            sequence: modelData.sequence
            context: Qt.ApplicationShortcut
            enabled: sequence.length > 0
            autoRepeat: false
            onActivated: root.action(modelData.id)
        }
    }
}
