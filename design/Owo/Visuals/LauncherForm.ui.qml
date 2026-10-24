// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 600
    height: 432
    property bool gridMode: true
    property alias searchField: searchField
    property alias gridButton: gridButton
    property alias listButton: listButton
    property alias closeButton: closeButton
    property alias gridView: gridView
    property alias listView: listView
    property var actionTarget: null
    property var applications: []
    property var appNames: ({})
    property var appDescriptions: ({})
    property string searchPlaceholder: "搜索应用 / Search applications"
    property int currentIndex: 0
    property string emptyText: "没有找到应用 / No applications found"
    property alias resultsArea: resultsArea
    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.space12
        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: searchField
                objectName: "launcherSearch"
                Layout.fillWidth: true
                implicitHeight: Tokens.controlHeight
                placeholderText: root.searchPlaceholder
                font: Tokens.body
                color: Tokens.textPrimary
                selectionColor: Tokens.primaryContainer
                selectedTextColor: Tokens.textPrimary
                selectByMouse: true
                Accessible.name: placeholderText
                background: Rectangle {
                    radius: Tokens.radiusM
                    color: Tokens.surface
                    border.width: searchField.activeFocus ? Tokens.space2 : Tokens.space1
                    border.color: searchField.activeFocus ? Tokens.primary : Tokens.surfaceEdge
                }
            }
            SmallButton {
                id: gridButton
                objectName: "launcherGridButton"
                iconName: "grid"
                text: "网格 / Grid"
                selected: root.gridMode
            }
            SmallButton {
                id: listButton
                objectName: "launcherListButton"
                iconName: "list"
                text: "列表 / List"
                selected: !root.gridMode
            }
            SmallButton {
                id: closeButton
                iconName: "close"
                text: "关闭 / Close"
            }
        }
        Item {
            id: resultsArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            GridView {
                id: gridView
                objectName: "launcherGridResults"
                anchors.fill: parent
                visible: root.gridMode
                clip: true
                model: root.applications
                currentIndex: root.currentIndex
                cellWidth: width / Math.max(2, Math.floor(width / 112))
                cellHeight: 100 * Tokens.textScale
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                delegate: AppTile {
                    required index
                    required appId
                    required property string displayName
                    required property string description
                    required property string iconName
                    width: gridView.cellWidth - Tokens.space8
                    height: gridView.cellHeight - Tokens.space8
                    label: root.appNames[appId] || displayName
                    detail: root.appDescriptions[appId] || description
                    actionTarget: root.actionTarget
                    glyph: iconName
                    selected: index === root.currentIndex
                }
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
            ListView {
                id: listView
                objectName: "launcherResults"
                anchors.fill: parent
                visible: !root.gridMode
                clip: true
                model: root.applications
                currentIndex: root.currentIndex
                spacing: Tokens.space4
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                delegate: AppTile {
                    required index
                    required appId
                    required property string displayName
                    required property string description
                    required property string iconName
                    width: listView.width - Tokens.space8
                    height: Tokens.launcherRow * Tokens.textScale
                    listMode: true
                    label: root.appNames[appId] || displayName
                    detail: root.appDescriptions[appId] || description
                    actionTarget: root.actionTarget
                    glyph: iconName
                    selected: index === root.currentIndex
                }
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
            Text {
                anchors.centerIn: parent
                visible: gridView.count === 0
                text: root.emptyText
                font: Tokens.body
                color: Tokens.textSecondary
            }
        }
    }
}
