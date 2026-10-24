// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

AnimatedAction {
    property int index: 0
    property var actionTarget: null
    onClicked: if (actionTarget)
        actionTarget.selectChoice(index)
}
