// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import KLDE.Backends

Flow {
    id: root
    required property int section
    signal action(string moduleId)
    readonly property var snapshot: Shell.state.snapshot
    property int layoutRevision: 0
    readonly property real naturalWidth: {
        const revision = layoutRevision;
        let width = 0, visibleCount = 0;
        for (let i = 0; i < modules.count; ++i) {
            const cell = modules.itemAt(i);
            if (cell && cell.visible) {
                width += cell.width;
                ++visibleCount;
            }
        }
        return width + Math.max(0, visibleCount - 1) * spacing;
    }
    spacing: Shell.ribbon.spacing
    Repeater {
        id: modules
        onItemAdded: root.layoutRevision += 1
        onItemRemoved: root.layoutRevision += 1
        model: Shell.ribbon.modules
        delegate: Loader {
            id: cell
            required property var modelData
            readonly property bool capable: modelData.id !== "battery" || root.snapshot.capabilities.battery
            readonly property bool densityVisible: Tokens.densityMode !== 0 || modelData.priority <= 3
            visible: modelData.enabled && modelData.section === root.section && capable && densityVisible
            active: visible
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0
            sourceComponent: Component {
                Item {
                    implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
                    implicitHeight: Tokens.ribbonHeight
                    Loader {
                        id: contentLoader
                        sourceComponent: cell.modelData.id === "workspaces" ? workspaceComponent : moduleComponent
                    }
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
                            onInvoked: moduleId => root.action(moduleId)
                        }
                    }
                }
            }
        }
    }
}
