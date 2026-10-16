// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick

QtObject {
    property bool darkMode: false
    property bool reducedMotion: false
    property real textScale: 1.0
    property bool transparencyEnabled: true
    property bool shadowsEnabled: true
    property int motionLevel: 1
    property string accentChoice: "auto"
    readonly property color accent: accentChoice === "lilac" ? accentLilac : accentChoice === "apricot" ? accentApricot : darkMode ? "#8ed3cd" : "#246c69"

    readonly property color background: darkMode ? "#151d22" : "#edf3f5"
    readonly property color surface: darkMode ? "#1e282e" : "#fcfdfd"
    readonly property color surfaceContainer: darkMode ? "#28343b" : "#e5edef"
    readonly property color surfaceElevated: darkMode ? "#303d45" : "#ffffff"
    readonly property color primary: accent
    readonly property color secondary: darkMode ? "#c4b9eb" : "#6e5b8d"
    readonly property color tertiary: darkMode ? "#f0c49e" : "#8a5732"
    readonly property color error: darkMode ? "#ffb4ab" : "#a82d3b"
    readonly property color outline: darkMode ? "#93a3ad" : "#647780"
    readonly property color textPrimary: darkMode ? "#edf4f6" : "#24343f"
    readonly property color textSecondary: darkMode ? "#bccbd2" : "#536975"
    readonly property color textDisabled: darkMode ? "#84949e" : "#75858e"
    readonly property color onPrimary: darkMode ? "#143c3a" : "#ffffff"
    readonly property color primaryContainer: Qt.tint(surface, Qt.rgba(primary.r, primary.g, primary.b, darkMode ? 0.22 : 0.14))
    readonly property color shadow: "#253c4c"
    readonly property real outlineOpacity: 0.20
    readonly property real shadowOpacity: 0.10
    readonly property real mutedOpacity: 0.35
    readonly property real popupStartScale: 0.96
    readonly property real darkWallpaperShade: 0.72
    readonly property real frostedSurfaceOpacity: darkMode ? 0.88 : 0.84
    readonly property real blurScaleLow: 0.25
    readonly property real blurScaleMedium: 0.50
    readonly property real blurScaleHigh: 0.75
    readonly property int blurTextureLimit: 1024
    readonly property color accentLilac: darkMode ? "#d6b8ed" : "#76518e"
    readonly property color accentApricot: darkMode ? "#efc29f" : "#885834"

    readonly property real surfaceOpacityLow: 0.72
    readonly property real surfaceOpacityMedium: 0.88
    readonly property real surfaceOpacityHigh: 0.97
    readonly property int radiusXS: 4
    readonly property int radiusS: 8
    readonly property int radiusM: 14
    readonly property int radiusL: 22
    readonly property int radiusXL: 32
    readonly property int radiusPill: 999

    readonly property int space1: 1
    readonly property int space2: 2
    readonly property int space3: 3
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32

    readonly property string fontFamily: Application.font.family
    readonly property font display: Qt.font({
        family: fontFamily,
        pixelSize: 48 * textScale,
        weight: Font.DemiBold
    })
    readonly property font headline: Qt.font({
        family: fontFamily,
        pixelSize: 30 * textScale,
        weight: Font.DemiBold
    })
    readonly property font title: Qt.font({
        family: fontFamily,
        pixelSize: 22 * textScale,
        weight: Font.Medium
    })
    readonly property font body: Qt.font({
        family: fontFamily,
        pixelSize: 16 * textScale
    })
    readonly property font label: Qt.font({
        family: fontFamily,
        pixelSize: 14 * textScale,
        weight: Font.Medium
    })
    readonly property font caption: Qt.font({
        family: fontFamily,
        pixelSize: 12 * textScale
    })

    readonly property real motionScale: motionLevel === 2 ? 1.2 : 1.0
    readonly property int motionFast: reducedMotion ? 0 : 120 * motionScale
    readonly property int motionNormal: reducedMotion ? 0 : 220 * motionScale
    readonly property int motionSlow: reducedMotion ? 0 : 360 * motionScale
    readonly property int emphasized: Easing.InOutCubic
    readonly property int emphasizedDecelerate: Easing.OutCubic
    readonly property int emphasizedAccelerate: Easing.InCubic
    readonly property int standard: Easing.InOutQuad
    readonly property int springLike: Easing.OutBack
    readonly property int elevationFlat: 0
    readonly property int elevationLow: 2
    readonly property int elevationMedium: 6
    readonly property int elevationHigh: 12
    readonly property int blurNone: 0
    readonly property int blurLow: 8
    readonly property int blurMedium: 16
    readonly property int blurHigh: 24

    readonly property int iconS: 18
    readonly property int iconM: 24
    readonly property int iconL: 40
    readonly property int dockIcon: 34
    readonly property int dockItem: 56 * densityScale
    readonly property int dockHeight: 80
    readonly property int controlHeight: 44 * densityScale
    readonly property int panelWidth: 392
    readonly property int settingsWidth: 600
    readonly property int settingsHeight: 664
    readonly property int sceneCardHeight: 112
    readonly property real densityScale: 1.0
    readonly property int launcherWidth: 600
    readonly property int launcherHeight: 528
    readonly property int launcherRow: 64 * densityScale
    readonly property int widgetSize: 224
    readonly property int desktopMargin: 40
    readonly property int blurSampleWidth: 320
    readonly property int blurSampleHeight: 180
    readonly property int previewWidth: 1440
    readonly property int previewHeight: 900
    readonly property int previewMinimumWidth: 960
    readonly property int previewMinimumHeight: 720
}
