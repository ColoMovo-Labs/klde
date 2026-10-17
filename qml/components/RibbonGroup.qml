// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import KLDE.Backends

Rectangle {
    id: root
    required property int section
    required property string groupId
    signal action(string moduleId)
    readonly property var snapshot: Shell.state.snapshot
    readonly property var entries: Shell.ribbon.modules.filter(m => m.id !== "time" && m.enabled && m.section === section && m.group === groupId && (m.id !== "battery" || snapshot.capabilities.battery) && (groupId === "telemetry" || Tokens.densityMode !== 0 || m.priority <= 3))
    width: groupId === "telemetry" ? telemetry.implicitWidth + Tokens.ribbonGroupPadding * 2 : row.implicitWidth + Tokens.ribbonGroupPadding * 2
    height: groupId === "telemetry" ? telemetry.implicitHeight + Tokens.ribbonGroupPadding * 2 : Tokens.ribbonHeight + Tokens.ribbonGroupPadding * 2
    radius: Tokens.radiusL
    color: Tokens.surface
    opacity: Tokens.transparencyEnabled ? Tokens.surfaceOpacityHigh : 1
    border.width: Tokens.space1
    border.color: Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
    Grid {
        id: telemetry
        visible: root.groupId === "telemetry"
        anchors.centerIn: parent
        columns: 2
        spacing: Tokens.space2
        Repeater {
            model: root.groupId === "telemetry" ? root.entries : []
            delegate: TelemetryCell {
                required property var modelData
                moduleId: modelData.id
                onClicked: root.action(moduleId)
            }
        }
    }
    Row {
        id: row
        visible: root.groupId !== "telemetry"
        anchors.centerIn: parent
        spacing: Tokens.ribbonInnerGap
        Repeater {
            model: root.groupId === "telemetry" ? [] : root.entries
            delegate: Loader {
                id: cell
                required property var modelData
                width: item ? item.implicitWidth : 0
                height: Tokens.ribbonHeight
                sourceComponent: modelData.id === "workspaces" ? workspaceComponent : moduleComponent
                Component {
                    id: workspaceComponent
                    WorkspaceIndicator {
                        compact: true
                    }
                }
                Component {
                    id: moduleComponent
                    StatusModule {
                        module: cell.modelData
                        grouped: true
                        onInvoked: moduleId => root.action(moduleId)
                    }
                }
            }
        }
    }
}
