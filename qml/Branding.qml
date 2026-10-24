// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick

QtObject {
    // Final public brand. KLDE/klde remain stable technical identifiers for
    // modules, packages and migration compatibility.
    readonly property string displayName: "owoDE"
    readonly property string expandedName: "owo Desktop Envirment · owo 桌面环境"
    readonly property string formalName: "owo Desktop Envirment"
    readonly property string iconName: "klde"
    // Stable technical IDs remain separate from replaceable public branding.
    readonly property string applicationId: "org.klde.shell.preview"
    readonly property string cacheNamespace: "klde"
}
