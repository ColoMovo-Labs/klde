// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
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
        anchors.margins: Tokens.space16
        height: sampleRibbon.implicitHeight
        RibbonForm {
            id: sampleRibbon
            anchors.fill: parent
            visible: root.showSamples
        }
    }
    Item {
        id: widgetHost
        x: Tokens.desktopMargin
        y: ribbonHost.y + ribbonHost.height + Tokens.space16 + Tokens.controlHeight
        width: Tokens.weatherWidgetSize
        height: width
        SurfaceForm {
            anchors.fill: parent
            visible: root.showSamples
            cornerRadius: width / 2
            tone: Tokens.surfaceContainerHigh
            WeatherForm {
                anchors.fill: parent
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
