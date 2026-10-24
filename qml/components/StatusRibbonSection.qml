// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import KLDE.Backends

Flow {
    id: root
    required property int section
    property int degradation: 0
    property Item backdropSource: null
    signal action(string moduleId)
    property int layoutRevision: 0
    readonly property real naturalWidth: {
        const revision = layoutRevision;
        let width = 0, count = 0;
        for (let i = 0; i < groups.count; ++i) {
            const item = groups.itemAt(i);
            if (item && item.visible) {
                width += item.width;
                ++count;
            }
        }
        return width + Math.max(0, count - 1) * spacing;
    }
    spacing: Tokens.ribbonGroupGap + Math.max(0, Shell.ribbon.spacing - Tokens.space6)
    // Flow moves the delegate wrapper, not its nested Surface. Refresh only
    // after layout or section movement so cached wallpaper samples stay aligned.
    function refreshBackdrops(): void {
        for (let i = 0; i < groups.count; ++i) {
            const item = groups.itemAt(i);
            if (item && item.visible)
                item.refreshBackdrop();
        }
    }
    onPositioningComplete: Qt.callLater(refreshBackdrops)
    onXChanged: Qt.callLater(refreshBackdrops)
    onYChanged: Qt.callLater(refreshBackdrops)
    Repeater {
        id: groups
        model: ["context", "date", "workspaces", "telemetry", "connectivity", "session", "extras"]
        onItemAdded: root.layoutRevision += 1
        onItemRemoved: root.layoutRevision += 1
        delegate: Item {
            id: groupCell
            required property string modelData
            width: group.width
            height: Tokens.ribbonBandHeight
            visible: group.entries.length > 0
            function refreshBackdrop(): void {
                group.refreshCapture();
            }
            RibbonGroup {
                id: group
                degradation: root.degradation
                section: root.section
                groupId: groupCell.modelData
                backdropSource: root.backdropSource
                y: (parent.height - height) / 2
                onAction: moduleId => root.action(moduleId)
            }
        }
    }
}
