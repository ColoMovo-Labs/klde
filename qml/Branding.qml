// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick

QtObject {
    readonly property string displayName: "LoMoDE"
    readonly property string expandedName: "LoMo Desktop Environment · 洛陌桌面环境"
    readonly property string iconName: "klde"
    // Stable technical IDs remain separate from replaceable public branding.
    readonly property string applicationId: "org.klde.shell.preview"
    readonly property string cacheNamespace: "klde"
}
