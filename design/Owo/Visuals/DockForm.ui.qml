// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var actionTarget: null
    property var applications: []
    property var appNames: ({})
    property alias launcherButton: launcherButton
    property alias row: dockRow
    property bool decorationVisible: true
    signal launcherRequested
    signal applicationRequested(string appId)
    width: dockRow.implicitWidth + Tokens.space24
    height: Tokens.dockHeight
    SurfaceForm {
        anchors.fill: parent
        visible: root.decorationVisible
    }
    Flickable {
        x: Tokens.space12
        width: root.width - Tokens.space24
        height: root.height
        contentWidth: dockRow.implicitWidth
        contentHeight: height
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: dockRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.space6
            SmallButton {
                id: launcherButton
                objectName: "launcherButton"
                width: Tokens.dockItem
                height: Tokens.dockItem
                iconName: "klde"
                text: Tokens.locale === "zh_CN" ? "应用" : "Applications"
                selected: true
            }
            Rectangle {
                width: Tokens.space1
                height: Tokens.space24
                anchors.verticalCenter: parent.verticalCenter
                color: Tokens.outline
                opacity: Tokens.mutedOpacity
            }
            Repeater {
                model: root.applications
                delegate: DockItem {
                    required appId
                    required property string displayName
                    required property string iconName
                    required property bool running
                    required property bool active
                    width: Tokens.dockItem
                    height: Tokens.dockItem
                    label: root.appNames[appId] || displayName
                    actionTarget: root.actionTarget
                    glyph: iconName
                    runningState: running
                    activeState: active
                }
            }
        }
    }
}
