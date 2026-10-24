// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 1440
    height: 900
    Rectangle {
        anchors.fill: parent
        color: Tokens.background
    }
    LanguageForm {
        anchors.centerIn: parent
    }
}
