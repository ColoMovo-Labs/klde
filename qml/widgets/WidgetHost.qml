// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

Loader {
    required property string widgetId
    property bool renderingAllowed: true
    active: visible && renderingAllowed
    // Phase 1 hosts trusted built-in Components, never external executable QML.
    asynchronous: false
}
