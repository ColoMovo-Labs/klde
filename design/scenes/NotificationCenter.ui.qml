// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals
import ".."

Item {
    width: 680
    height: 720
    SurfaceForm {
        anchors.fill: parent
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.space24
        spacing: Tokens.space16
        PanelHeaderForm {
            Layout.fillWidth: true
            title: "通知中心"
            subtitle: "模拟通知 / Mock notifications"
        }
        NotificationCardForm {
            Layout.fillWidth: true
        }
        NotificationCardForm {
            Layout.fillWidth: true
            sourceName: "更新"
            heading: "可用更新"
            body: "系统后端尚未连接，不会自动安装。"
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
