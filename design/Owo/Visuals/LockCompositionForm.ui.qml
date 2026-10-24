// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1440
    height: 900
    property alias clockHost: clockHost
    property string timeText: "08:30"
    property string dateText: "10月17日 周六"
    property string notice: "锁屏视觉预览 · 不提供认证 / Visual preview only"
    property bool showSampleClock: true
    Item {
        id: clockHost
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Tokens.space24
        width: Math.min(parent.width - Tokens.lockScreenEdgeMargin * 2, 720)
        height: 272 * Tokens.textScale
        Column {
            anchors.centerIn: parent
            spacing: Tokens.space12
            visible: root.showSampleClock
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeText
                font.family: Tokens.displayClockFont
                font.pixelSize: 164 * Tokens.textScale
                font.weight: Tokens.displayClockWeight
                color: Tokens.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.dateText
                font: Tokens.title
                color: Tokens.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.notice
                font: Tokens.caption
                color: Tokens.textSecondary
            }
        }
    }
}
