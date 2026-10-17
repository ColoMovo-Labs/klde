// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick

QtObject {
    property bool darkMode: false
    property bool reducedMotion: false
    property real textScale: 1.0
    property bool transparencyEnabled: true
    property bool shadowsEnabled: true
    property int motionLevel: 2
    property int densityMode: 1
    property int shadowLevel: 1
    property bool debugGeometry: false
    property string wallpaperChoice: "snow"
    property string accentChoice: "auto"
    readonly property color accent: accentChoice === "teal" ? accentTeal : accentChoice === "lilac" ? accentLilac : accentChoice === "apricot" ? accentApricot : darkMode ? "#99d1c8" : wallpaperChoice === "abstract" ? "#5545ad" : wallpaperChoice === "kemono" ? "#76518e" : "#07679e"

    readonly property color background: darkMode ? "#10182b" : "#edf2ff"
    readonly property color surface: darkMode ? "#19283e" : "#f9faff"
    readonly property color surfaceContainer: darkMode ? "#263650" : "#e8eaff"
    readonly property color surfaceElevated: darkMode ? "#223148" : "#ffffff"
    readonly property color primary: accent
    readonly property color secondary: darkMode ? "#dfc0ff" : "#8554bf"
    readonly property color tertiary: darkMode ? "#f0c49e" : "#8a5732"
    readonly property color error: darkMode ? "#ffb4ab" : "#a82d3b"
    readonly property color outline: darkMode ? "#8fa5c5" : "#747fa6"
    readonly property color textPrimary: darkMode ? "#eef3ff" : "#20264d"
    readonly property color textSecondary: darkMode ? "#bacbe1" : "#566287"
    readonly property color textDisabled: darkMode ? "#84949e" : "#75858e"
    readonly property color textOnPrimary: darkMode ? "#152633" : "#ffffff"
    readonly property color primaryContainer: Qt.tint(surface, Qt.rgba(primary.r, primary.g, primary.b, darkMode ? 0.22 : 0.14))
    readonly property color surfaceVariant: surfaceContainer
    readonly property color warning: darkMode ? "#f4ca86" : "#805200"
    readonly property color success: darkMode ? "#9ed5ad" : "#27683a"
    readonly property color shadow: darkMode ? "#070e20" : "#292e6b"
    readonly property real outlineOpacity: 0.20
    readonly property real shadowOpacity: darkMode ? 0.30 : 0.14
    readonly property real mutedOpacity: 0.35
    readonly property real popupStartScale: 0.96
    readonly property real frostedSurfaceOpacity: darkMode ? 0.88 : 0.80
    readonly property real blurScaleLow: 0.25
    readonly property real blurScaleMedium: 0.50
    readonly property real blurScaleHigh: 0.75
    readonly property int blurTextureLimit: 1024
    readonly property color accentTeal: darkMode ? "#99d1c8" : "#22685d"
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

    readonly property bool cjk: I18n.locale === "zh_CN"
    readonly property FontLoader glowRegular: FontLoader {
        source: "qrc:/assets/fonts/glow-sans/GlowSansSC-Normal-Regular.otf"
    }
    readonly property FontLoader glowMedium: FontLoader {
        source: "qrc:/assets/fonts/glow-sans/GlowSansSC-Normal-Medium.otf"
    }
    readonly property string fontFamily: glowRegular.status === FontLoader.Ready ? glowRegular.name : cjk ? "Noto Sans CJK SC" : Application.font.family
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
        pixelSize: (cjk ? 15 : 14) * textScale,
        weight: Font.Medium
    })
    readonly property font caption: Qt.font({
        family: fontFamily,
        pixelSize: (cjk ? 13 : 12) * textScale
    })

    readonly property real motionScale: motionLevel === 3 ? 0.8 : motionLevel === 2 ? 1.2 : 1.0
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
    readonly property int panelWidth: 408
    readonly property int settingsWidth: 600
    readonly property int settingsHeight: 664
    readonly property int sceneCardHeight: 112
    readonly property int sliderHeight: 52 * densityScale
    readonly property int toggleHeight: 84 * densityScale
    readonly property int toggleIcon: 44 * densityScale
    readonly property real densityScale: densityMode === 0 ? 1.12 : densityMode === 2 ? 0.92 : 1.0
    readonly property int ribbonHeight: densityMode === 0 ? 44 : 40
    readonly property int rowGap: densityMode === 0 ? space16 : densityMode === 2 ? space8 : space12
    readonly property FontLoader clockFace: FontLoader {
        source: "qrc:/assets/fonts/rubik/Rubik[wght].ttf"
    }
    readonly property string displayClockFont: clockFace.status === FontLoader.Ready ? clockFace.name : "Sans Serif"
    readonly property int displayClockWeight: Font.ExtraBold
    readonly property real displayClockTracking: -1 * textScale
    readonly property real displayClockDigitWidth: 0.64
    readonly property real displayClockColonWidth: 0.28
    readonly property int ambientClockSize: 224
    readonly property int workingClockSize: 56
    readonly property int ambientMediaThreshold: 420
    // Keep the lower media affordance out of the central clock's short-surface budget.
    readonly property int ambientMediaMinimumHeight: 520
    readonly property int ribbonGroupGap: densityMode === 2 ? space12 : space16
    readonly property int ribbonInnerGap: space2
    readonly property int ribbonGroupPadding: space4
    readonly property int telemetryCellWidth: 72
    readonly property int telemetryCompactWidth: 60
    readonly property int telemetryIcon: 14
    readonly property int ribbonCondenseThreshold: 1500
    readonly property int ribbonFoldThreshold: 1160
    readonly property int telemetryCellHeight: 18
    readonly property int temporalWidth: 208
    readonly property int temporalHeight: 48
    readonly property int temporalCompactWidth: 160
    readonly property int temporalCompactHeight: 40
    readonly property int temporalExpandedWidth: 400
    readonly property int temporalExpandedHeight: 144
    readonly property int temporalFont: 28
    readonly property int temporalCompactFont: 23
    readonly property int temporalExpandedFont: 48
    readonly property int temporalCompactInset: 12
    readonly property int temporalInset: 16
    readonly property int temporalExpandedInset: 24
    readonly property real temporalOrbRatio: 0.40
    readonly property var temporalPalettes: ({
            "clear-morning": ["#aaa1dc", "#f5d7b4"],
            "cloudy-day": ["#8dc6eb", "#d9eff6"],
            "sunset": ["#8272b3", "#f3ae9d"],
            "rainy-evening": ["#526781", "#9aafbf"],
            "starry-night": ["#111b42", "#33476e"],
            "moonlit-night": ["#163f59", "#53858c"]
        })
    readonly property color temporalDayOrb: "#fff0bb"
    readonly property color temporalSunsetOrb: "#ffcd88"
    readonly property color temporalText: "#ffffff"
    // A quiet contrast wash; the clock remains light text without a halo/outline.
    readonly property color temporalInkVeil: "#a614243c"
    readonly property color temporalEdge: "#507f94b6"
    readonly property color surfaceEdge: Qt.rgba(outline.r, outline.g, outline.b, outlineOpacity)
    readonly property int temporalStudyWidth: 1160
    readonly property int temporalStudyCardHeight: 144
    readonly property int ribbonBandHeight: Math.max(temporalHeight, ribbonHeight + ribbonGroupPadding * 2, telemetryCellHeight * 2 + space2 + ribbonGroupPadding * 2)
    readonly property int ribbonStackThreshold: 880
    readonly property real depthLow: 0.015
    readonly property real depthMedium: 0.025
    readonly property real depthHigh: 0.035
    readonly property real displayClockLineHeight: 1.14
    readonly property real displayClockColonDot: 0.085
    readonly property real displayClockColonGap: 0.18
    readonly property real wallpaperDim: 0.16
    readonly property int ribbonIcon: 22
    readonly property int ribbonPadding: densityMode === 2 ? space6 : space8
    readonly property int capsuleBorderWidth: 1
    readonly property int capsuleHorizontalPadding: space8
    readonly property int capsuleVerticalPadding: space4
    readonly property int capsuleIconSize: 22
    readonly property int capsuleIconTextGap: space4
    readonly property int lockScreenEdgeMargin: 48
    readonly property int lockScreenContentWidth: 360
    readonly property int launcherWidth: 600
    readonly property int launcherHeight: 528
    readonly property int launcherRow: 64 * densityScale
    readonly property int widgetSize: 224
    readonly property int desktopMargin: 28
    readonly property int blurSampleWidth: 320
    readonly property int blurSampleHeight: 180
    readonly property int previewWidth: 1440
    readonly property int previewHeight: 900
    readonly property int previewMinimumWidth: 640
    readonly property int previewMinimumHeight: 640
}
