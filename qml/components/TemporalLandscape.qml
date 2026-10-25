// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Window
import KLDE.Backends

TemporalLandscapeForm {
    id: root
    readonly property bool rainy: phase === "rainy-evening"
    readonly property bool night: phase === "starry-night" || phase === "moonlit-night"
    readonly property bool activeMotion: visible && Shell.blur.renderingAllowed && !Tokens.reducedMotion
    Behavior on sunX {
        enabled: root.activeMotion
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    Behavior on sunY {
        enabled: root.activeMotion
        NumberAnimation {
            duration: Tokens.springSpatialMicro.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatialMicro.curve
        }
    }
    property bool initialized: false
    Component.onCompleted: initialized = true
    onPhaseChanged: if (initialized && activeMotion)
        sceneTransition.restart()
    onActiveMotionChanged: if (initialized && !activeMotion) {
        sceneTransition.stop();
        opacity = 1;
    }
    NumberAnimation {
        id: sceneTransition
        target: root
        property: "opacity"
        to: 1
        duration: Tokens.motionNormal
        easing.type: Tokens.emphasizedDecelerate
    }
}
