// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import KLDE.Backends

Rectangle {
    id: root
    required property int section
    property int degradation: 0
    required property string groupId
    signal action(string moduleId)
    // The ink weight of icon/text combinations is not symmetrical even when
    // their layout bounds are.  These tiny optical corrections keep the
    // visible group centered without changing its measured width.
    readonly property real opticalCenterOffset: groupId === "context" || groupId === "connectivity" ? -Tokens.space2 : groupId === "session" ? Tokens.space2 : 0
    readonly property bool batteryAvailable: Shell.state.snapshot.capabilities.battery
    readonly property var entries: Shell.ribbon.modules.filter(m => m.id !== "time" && m.enabled && m.section === root.section && m.group === root.groupId && (m.id !== "battery" || root.batteryAvailable) && !(root.degradation >= 1 && ["microphone", "scene", "weather", "overview"].indexOf(m.id) >= 0) && !(root.degradation >= 2 && ["bluetooth", "date", "input"].indexOf(m.id) >= 0) && !(root.degradation >= 2 && root.groupId === "telemetry"))
    width: groupId === "telemetry" ? telemetry.implicitWidth + Tokens.ribbonGroupPadding * 2 : row.implicitWidth + Tokens.ribbonGroupPadding * 2
    // All top-ribbon groups share one optical band.  The telemetry grid is
    // centered inside it instead of producing a two-pixel-short capsule.
    height: Tokens.ribbonBandHeight
    objectName: "ribbonGroup-" + groupId
    radius: height / 2
    color: Tokens.surface
    opacity: Tokens.transparencyEnabled ? Tokens.surfaceOpacityHigh : 1
    border.width: Tokens.capsuleBorderWidth
    border.color: Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
    Grid {
        id: telemetry
        visible: root.groupId === "telemetry"
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.opticalCenterOffset
        columns: 2
        spacing: Tokens.space2
        Repeater {
            model: root.groupId === "telemetry" ? root.entries : []
            delegate: TelemetryCell {
                required property var modelData
                condensed: root.degradation > 0
                moduleId: modelData.id
                onClicked: root.action(moduleId)
            }
        }
    }
    Row {
        id: row
        visible: root.groupId !== "telemetry"
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.opticalCenterOffset
        spacing: Tokens.ribbonInnerGap
        Repeater {
            model: root.groupId === "telemetry" ? [] : root.entries
            delegate: Loader {
                id: cell
                required property var modelData
                width: item ? (item as Item).implicitWidth : 0
                height: Tokens.ribbonHeight
                sourceComponent: modelData.id === "workspaces" ? workspaceComponent : moduleComponent
                Component {
                    id: workspaceComponent
                    WorkspaceIndicator {
                        compact: true
                        grouped: true
                    }
                }
                Component {
                    id: moduleComponent
                    StatusModule {
                        module: cell.modelData
                        condensed: root.degradation > 0
                        grouped: true
                        onInvoked: moduleId => root.action(moduleId)
                    }
                }
            }
        }
    }
}
