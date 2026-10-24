// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: Tokens.previewWidth
    height: Tokens.previewHeight
    property bool showSamples: true
    property alias backgroundHost: backgroundHost
    property alias ribbonHost: ribbonHost
    property alias dockHost: dockHost
    property alias widgetHost: widgetHost
    property var applications: []
    Item {
        id: backgroundHost
        anchors.fill: parent
        BackgroundForm {
            anchors.fill: parent
            visible: root.showSamples
        }
    }
    Item {
        id: ribbonHost
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Tokens.ribbonBandHeight + Tokens.space32
        RibbonForm {
            anchors.fill: parent
            visible: root.showSamples
        }
    }
    Item {
        id: widgetHost
        x: Tokens.desktopMargin
        y: ribbonHost.height + Tokens.controlHeight
        width: Tokens.weatherWidgetSize
        height: width
        SurfaceForm {
            anchors.fill: parent
            visible: root.showSamples
            cornerRadius: width / 2
            Column {
                anchors.centerIn: parent
                spacing: Tokens.space8
                Glyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "weather"
                    width: Tokens.weatherIcon
                    height: width
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "21°"
                    font: Tokens.weatherTemperature
                    color: Tokens.primary
                }
                Text {
                    text: "Snowline · 模拟天气"
                    font: Tokens.caption
                    color: Tokens.textSecondary
                }
            }
        }
    }
    Item {
        id: dockHost
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space24
        width: parent.width
        height: Tokens.dockHeight
        DockForm {
            anchors.centerIn: parent
            applications: root.applications
            visible: root.showSamples
        }
    }
}
