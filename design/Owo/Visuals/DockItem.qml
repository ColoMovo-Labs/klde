// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

DockItemForm {
    property string appId: ""
    property var actionTarget: null
    onClicked: if (actionTarget)
        actionTarget.activateApp(appId, -1)
}
