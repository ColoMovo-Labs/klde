// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 760
    height: 700
    SurfaceForm {
        anchors.fill: parent
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.space24
        PanelHeaderForm {
            Layout.fillWidth: true
            title: "设置"
            subtitle: "视觉预览 / Design Preview"
        }
        SettingsForm {
            Layout.fillWidth: true
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
