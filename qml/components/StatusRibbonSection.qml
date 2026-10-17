// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import KLDE.Backends

Flow {
    id: root
    required property int section
    signal action(string moduleId)
    spacing: Tokens.ribbonGroupGap + Math.max(0, Shell.ribbon.spacing - Tokens.space6)
    Repeater {
        model: ["context", "date", "workspaces", "telemetry", "connectivity", "session", "extras"]
        delegate: RibbonGroup {
            required property string modelData
            section: root.section
            groupId: modelData
            visible: entries.length > 0
            onAction: moduleId => root.action(moduleId)
        }
    }
}
