// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import KLDE.Backends

// A small "simulated" marker placed next to a control whose data does not come
// from a real service. With a state path it disappears once that path is live.
Rectangle {
    id: root
    property string path: ""
    property bool mock: path.length > 0 ? Shell.state.livePaths.indexOf(path) < 0 : true
    visible: mock
    implicitWidth: badgeText.implicitWidth + Tokens.space12
    implicitHeight: badgeText.implicitHeight + Tokens.space4
    radius: Tokens.radiusPill
    color: Tokens.surfaceVariant
    Accessible.role: Accessible.StaticText
    Accessible.name: I18n.t("settings.mock.accessible")
    Text {
        id: badgeText
        anchors.centerIn: parent
        text: I18n.t("settings.mock.badge")
        font: Tokens.caption
        color: Tokens.textSecondary
    }
}
