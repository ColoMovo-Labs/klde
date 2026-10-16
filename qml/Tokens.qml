// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick

QtObject {
    property bool darkMode: false
    property bool reducedMotion: false
    property real textScale: 1.0
    property color accent: darkMode ? "#8ed3cd" : "#246c69"

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

    readonly property string fontFamily: Qt.application.font.family
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

    readonly property int motionFast: reducedMotion ? 0 : 120
    readonly property int motionNormal: reducedMotion ? 0 : 220
    readonly property int motionSlow: reducedMotion ? 0 : 360
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

    readonly property int previewWidth: 960
    readonly property int previewHeight: 600
    readonly property int previewMinimumWidth: 640
    readonly property int previewMinimumHeight: 400
}
