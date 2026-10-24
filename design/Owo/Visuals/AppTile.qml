// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

AppTileForm {
    property string appId: ""
    property int index: 0
    property var actionTarget: null
    onClicked: if (actionTarget)
        actionTarget.activateApp(appId, index)
}
