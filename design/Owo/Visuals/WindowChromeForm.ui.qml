// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 600
    height: 380
    property alias title: titleLabel.text
    SurfaceForm {
        anchors.fill: parent
        cornerRadius: Tokens.radiusL
    }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.space12
        Glyph {
            name: "folder"
            Layout.preferredWidth: Tokens.iconM
            Layout.preferredHeight: Tokens.iconM
        }
        Text {
            id: titleLabel
            text: "owoDE · 窗口视觉"
            font: Tokens.label
            color: Tokens.textPrimary
            Layout.fillWidth: true
        }
        SmallButton {
            iconName: "minus"
            text: "最小化 / Minimize"
        }
        SmallButton {
            iconName: "grid"
            text: "最大化 / Maximize"
        }
        SmallButton {
            iconName: "close"
            text: "关闭 / Close"
        }
    }
}
