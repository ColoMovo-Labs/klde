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
    readonly property var monetPalette: MonetPalette.paletteFor(wallpaperChoice, darkMode)
    readonly property color accent: accentChoice === "teal" ? accentTeal : accentChoice === "lilac" ? accentLilac : accentChoice === "apricot" ? accentApricot : monetPalette.primary

    // These are Material Expressive-style semantic roles.  The seed comes from
    // the selected wallpaper so the entire shell moves together as one palette,
    // instead of recoloring individual widgets independently.
    readonly property color background: monetPalette.background
    readonly property color surface: monetPalette.surface
    readonly property color surfaceContainer: monetPalette.surfaceContainer
    readonly property color surfaceElevated: monetPalette.surfaceElevated
    readonly property color surfaceContainerHigh: Qt.tint(surfaceContainer, Qt.rgba(accent.r, accent.g, accent.b, darkMode ? 0.12 : 0.08))
    readonly property color surfaceContainerHighest: Qt.tint(surfaceElevated, Qt.rgba(accent.r, accent.g, accent.b, darkMode ? 0.18 : 0.10))
    readonly property color surfaceDim: darkMode ? Qt.darker(surface, 1.18) : Qt.darker(surface, 1.03)
    readonly property color surfaceBright: darkMode ? Qt.lighter(surfaceElevated, 1.12) : surfaceElevated
    readonly property color primary: accent
    readonly property color secondary: accentChoice === "auto" ? monetPalette.secondary : darkMode ? "#dfc0ff" : "#8554bf"
    readonly property color tertiary: monetPalette.tertiary
    readonly property color error: darkMode ? "#ffb4ab" : "#a82d3b"
    readonly property color outline: monetPalette.outline
    readonly property color textPrimary: monetPalette.textPrimary
    readonly property color textSecondary: monetPalette.textSecondary
    readonly property color textDisabled: monetPalette.textDisabled
    readonly property color textOnPrimary: accentChoice === "auto" ? monetPalette.onPrimary : darkMode ? "#152633" : "#ffffff"
    readonly property color primaryContainer: accentChoice === "auto" ? monetPalette.primaryContainer : Qt.tint(surface, Qt.rgba(primary.r, primary.g, primary.b, darkMode ? 0.22 : 0.14))
    readonly property color surfaceVariant: monetPalette.secondaryContainer
    readonly property color warning: monetPalette.warning
    readonly property color success: monetPalette.success
    readonly property color shadow: monetPalette.shadow
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

    // Damped-spring motion from the Material Expressive physics model. Each spring
    // is baked into a finite Bezier spline, so animations keep a fixed duration,
    // honour reduced motion and settle for the idle audit like every other token.
    function springCurve(dampingRatio: real, stiffness: real): var {
        const omega = Math.sqrt(stiffness);
        const zeta = Math.min(dampingRatio, 1.0);
        const decay = zeta * omega;
        const damped = omega * Math.sqrt(Math.max(1 - zeta * zeta, 0));
        const position = t => zeta < 1 ? 1 - Math.exp(-decay * t) * (Math.cos(damped * t) + decay / damped * Math.sin(damped * t)) : 1 - Math.exp(-omega * t) * (1 + omega * t);
        const velocity = t => zeta < 1 ? omega / Math.sqrt(1 - zeta * zeta) * Math.exp(-decay * t) * Math.sin(damped * t) : omega * omega * t * Math.exp(-omega * t);
        const envelope = t => zeta < 1 ? Math.exp(-decay * t) / Math.sqrt(1 - zeta * zeta) : Math.exp(-omega * t) * (1 + omega * t);
        let settle = 0.004;
        while (envelope(settle) > springSettleError && settle < 2)
            settle += 0.004;
        // QEasingCurve's BezierSpline preallocates ten segments and writes past
        // them without bounds checks (Qt 6.10/6.11), so never exceed springSegments.
        const segments = springSegments;
        const curve = [];
        for (let i = 1; i <= segments; ++i) {
            const start = (i - 1) / segments, end = i / segments, step = 1 / segments;
            const y0 = position(start * settle), d0 = velocity(start * settle) * settle;
            const y1 = i === segments ? 1 : position(end * settle);
            const d1 = i === segments ? 0 : velocity(end * settle) * settle;
            curve.push(start + step / 3, y0 + d0 * step / 3, end - step / 3, y1 - d1 * step / 3, end, y1);
        }
        return {
            duration: Math.round(settle * 1000),
            curve: curve
        };
    }
    function spring(dampingRatio: real, stiffness: real): var {
        const baked = springCurve(dampingRatio, stiffness);
        return {
            duration: reducedMotion ? 0 : Math.round(baked.duration * springSpeed),
            curve: baked.curve
        };
    }
    readonly property real springSettleError: 0.0008
    readonly property int springSegments: 10
    readonly property bool expressiveMotion: motionLevel === 2
    readonly property real springSpeed: motionLevel === 3 ? 0.8 : 1.0
    // Spatial springs move and resize. Keep production overshoot restrained: the
    // large 9% bounce of the old fast curve read as a jelly-like UI on controls.
    readonly property var springSpatialFast: expressiveMotion ? spring(0.72, 1500) : spring(0.9, 1400)
    readonly property var springSpatialMicro: expressiveMotion ? spring(0.80, 2200) : spring(0.94, 2600)
    readonly property var springHover: expressiveMotion ? spring(0.88, 1200) : spring(0.96, 1500)
    readonly property var springPopup: expressiveMotion ? spring(0.82, 480) : spring(0.94, 650)
    readonly property var springSpatial: expressiveMotion ? spring(0.8, 380) : spring(0.9, 700)
    readonly property var springSpatialSlow: expressiveMotion ? spring(0.8, 200) : spring(0.9, 300)
    // Effect springs drive colour and opacity and are always critically damped.
    readonly property var springEffectsFast: spring(1.0, 3800)
    readonly property var springEffects: spring(1.0, 1600)
    readonly property var springEffectsSlow: spring(1.0, 800)
    readonly property int springStagger: reducedMotion ? 0 : 40
    readonly property real pressScale: 0.975
    readonly property real hoverScale: 1.012
    readonly property real hoverLift: 1

    // Material tiers for the fusion study. Mica is a calm wallpaper-tinted base,
    // Acrylic a grained transient layer with an elevation rim, Glass a refracting
    // floating control. All sample only KLDE-owned wallpaper; see blur.md.
    readonly property var materials: ({
            "mica": {
                tint: surface,
                captureScale: 0.125,
                blur: 1.0,
                blurMax: 64,
                tintOpacity: darkMode ? 0.80 : 0.70,
                saturation: 0.75,
                grain: 0.0,
                rim: 0.12,
                specular: 0.0,
                refraction: 0.0,
                edge: 0.0,
                dispersion: 0.0,
                shadow: 0
            },
            "acrylic": {
                tint: surfaceElevated,
                captureScale: 0.25,
                blur: 1.0,
                blurMax: 40,
                tintOpacity: darkMode ? 0.66 : 0.58,
                saturation: 1.0,
                grain: 0.035,
                rim: 0.34,
                specular: 0.0,
                refraction: 0.0,
                edge: 0.0,
                dispersion: 0.0,
                shadow: 2
            },
            "glass": {
                tint: darkMode ? "#1b2333" : "#ffffff",
                captureScale: 0.5,
                blur: 0.3,
                blurMax: 16,
                tintOpacity: darkMode ? 0.20 : 0.14,
                saturation: 1.18,
                grain: 0.0,
                rim: 0.65,
                specular: 1.0,
                refraction: 16.0,
                edge: 22.0,
                dispersion: 0.22,
                shadow: 1
            }
        })
    readonly property point materialLight: Qt.point(-0.45, -0.89)
    readonly property real glassPressScale: 0.97
    readonly property real expressivePressScale: 0.94
    readonly property real revealScale: 0.92
    readonly property int revealLift: space24
    readonly property int materialLabelWidth: 184
    readonly property int materialSpecimenWidth: 440
    readonly property int materialFlyoutWidth: 280
    readonly property int materialPanelHeight: 212
    readonly property int materialFlyoutHeight: 148
    readonly property int materialDockHeight: 76
    readonly property int materialMotionHeight: 84
    readonly property int materialMenuRow: 36
    readonly property int materialIndicatorWidth: 3
    readonly property int materialIndicatorHeight: 16
    readonly property int materialSwitchWidth: 52
    readonly property int materialSwitchHeight: 32
    readonly property int materialThumbOff: 16
    readonly property int materialThumbOn: 24
    readonly property int materialThumbPressed: 28
    readonly property int materialHoverLift: space4
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
    readonly property int ribbonInnerGap: space1
    readonly property int ribbonGroupPadding: space3
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
    readonly property int capsuleHorizontalPadding: space12
    readonly property int capsuleVerticalPadding: space4
    readonly property int capsuleIconSize: 22
    readonly property int capsuleIconTextGap: space3
    readonly property int weatherWidgetSize: 184
    readonly property int weatherWidgetPadding: 20
    readonly property int weatherIcon: 32
    readonly property font weatherTemperature: Qt.font({
        family: fontFamily,
        pixelSize: 40 * textScale,
        weight: Font.DemiBold
    })
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
