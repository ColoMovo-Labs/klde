// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals

AppTileForm {
    id: root
    scale: down ? Tokens.pressScale : hovered ? Tokens.hoverScale : 1
    Behavior on scale {
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    property string appId: ""
    property int index: 0
    property var actionTarget: null
    onClicked: if (actionTarget)
        actionTarget.activateApp(appId, index)
    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: root.actionTarget !== null && typeof root.actionTarget.requestApplicationMenu === "function"
        onTapped: root.actionTarget.requestApplicationMenu(root.appId)
    }
    Keys.onPressed: event => {
        if ((event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) && actionTarget && typeof actionTarget.requestApplicationMenu === "function") {
            actionTarget.requestApplicationMenu(appId);
            event.accepted = true;
        }
    }
}
