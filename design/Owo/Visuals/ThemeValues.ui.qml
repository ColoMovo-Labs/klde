// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Edit these root properties in QDS Properties. Manual color override is opt-in;
// wallpaper-derived Monet colors remain the default in both runtimes.
Item {
    id: root
    width: 720
    height: 200
    property bool manualColors: false
    property int displaySize: 48
    property int headlineSize: 30
    property int titleSize: 22
    property int bodySize: 16
    property int labelSize: 14
    property int captionSize: 12
    property real surfaceOpacityLow: 0.72
    property real surfaceOpacityMedium: 0.88
    property real surfaceOpacityHigh: 0.97
    property int elevationLow: 2
    property int elevationMedium: 6
    property int elevationHigh: 12
    property int radiusXS: 4
    property int radiusS: 8
    property int radiusM: 14
    property int radiusL: 22
    property int radiusXL: 32
    property int radiusPill: 999
    property int space1: 1
    property int space2: 2
    property int space3: 3
    property int space4: 4
    property int space6: 6
    property int space8: 8
    property int space12: 12
    property int space16: 16
    property int space24: 24
    property int space32: 32
    property int space64: 64
    property int panelWidth: 408
    property int dockHeight: 80
    property int launcherWidth: 600
    property int launcherHeight: 500
    property int motionFastMs: 120
    property int motionNormalMs: 220
    property int motionSlowMs: 360
    property color backgroundLight: "#e8efff"
    property color backgroundDark: "#131b2b"
    property color surfaceLight: "#f5f7fe"
    property color surfaceDark: "#202a3d"
    property color surfaceContainerLight: "#e2eaf6"
    property color surfaceContainerDark: "#28364a"
    property color surfaceElevatedLight: "#fafbff"
    property color surfaceElevatedDark: "#334057"
    property color primaryLight: "#146ea6"
    property color primaryDark: "#9accf0"
    property color secondaryLight: "#64638a"
    property color secondaryDark: "#cdc5eb"
    property color tertiaryLight: "#835879"
    property color tertiaryDark: "#e9b7dc"
    property color errorLight: "#a82d3b"
    property color errorDark: "#ffb4ab"
    property color outlineLight: "#77849b"
    property color outlineDark: "#9daac1"
    property color textPrimaryLight: "#15233c"
    property color textPrimaryDark: "#e6edfa"
    property color textSecondaryLight: "#526482"
    property color textSecondaryDark: "#b3c2d9"
    property color textDisabledLight: "#8898ae"
    property color textDisabledDark: "#7d8ca4"
    property color textOnPrimaryLight: "#ffffff"
    property color textOnPrimaryDark: "#123148"
    property color primaryContainerLight: "#cce8ff"
    property color primaryContainerDark: "#264b67"
    Row {
        anchors.centerIn: parent
        spacing: root.space16
        Rectangle {
            width: 180
            height: 120
            radius: root.radiusL
            color: root.primaryLight
        }
        Rectangle {
            width: 180
            height: 120
            radius: root.radiusL
            color: root.primaryDark
        }
        Rectangle {
            width: 180
            height: 120
            radius: root.radiusL
            color: root.surfaceLight
            border.color: root.outlineLight
            border.width: 1
        }
    }
}
