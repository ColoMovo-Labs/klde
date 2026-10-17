// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import KLDE.Backends

SliderCard {
    id: root
    required property string path
    readonly property var snapshot: Shell.state.snapshot
    value: {
        const revision = snapshot;
        return Shell.state.value(path);
    }
    Layout.fillWidth: true
    onValueRequested: requestedValue => Shell.state.requestValue(path, requestedValue)
}
