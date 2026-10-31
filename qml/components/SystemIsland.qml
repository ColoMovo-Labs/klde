// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Item {
    id: root
    readonly property bool nativeInputSurface: true
    property string stateName: "idle"
    property string sizeMode: "standard"
    property bool expanded: false
    property var readingOverride: null
    readonly property bool idle: stateName === "idle"
    readonly property int eventPriority: ({
            "critical": 8,
            "authorization": 7,
            "privacy": 6,
            "media": 5,
            "device": 4,
            "progress": 3,
            "notification": 2,
            "idle": 0
        })[stateName] || 0
    readonly property Item debugContentItem: capsule.debugContentItem
    readonly property Item debugTextItem: capsule.debugTextItem
    readonly property var reading: readingOverride || Shell.time.reading
    signal clicked

    function requestState(nextState: string, priority: int): bool {
        if (priority < eventPriority)
            return false;
        stateName = nextState;
        expanded = false;
        return true;
    }

    function returnToIdle(): void {
        stateName = "idle";
        expanded = false;
    }

    implicitWidth: idle ? capsule.implicitWidth : expanded ? 320 : 236
    implicitHeight: idle ? capsule.implicitHeight : expanded ? 80 : 48
    width: implicitWidth
    height: implicitHeight
    Behavior on width {
        NumberAnimation {
            duration: Tokens.springSpatial.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatial.curve
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Tokens.springSpatial.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatial.curve
        }
    }

    TemporalCapsule {
        id: capsule
        visible: root.idle
        anchors.centerIn: parent
        readingOverride: root.reading
        sizeMode: root.sizeMode
        onClicked: root.clicked()
    }

    Rectangle {
        id: islandSurface
        visible: !root.idle
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: height / 2
        color: Tokens.surfaceContainerHigh
        border.width: Tokens.capsuleBorderWidth
        border.color: Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
        Behavior on color {
            ColorAnimation {
                duration: Tokens.springEffectsFast.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Tokens.springEffectsFast.curve
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.space12
            anchors.rightMargin: Tokens.space12
            spacing: Tokens.space8
            Icon {
                name: root.stateName === "authorization" ? "settings" : root.stateName === "privacy" ? "microphone" : root.stateName === "media" ? "music" : root.stateName === "critical" ? "power" : root.stateName === "progress" ? "overview" : root.stateName === "device" ? "bluetooth" : "bell"
                Layout.preferredWidth: Tokens.iconM
                Layout.preferredHeight: Tokens.iconM
                lightInk: Tokens.darkMode
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    text: root.stateName === "authorization" ? I18n.t("island.authorization") : root.stateName === "privacy" ? I18n.t("island.privacy") : root.stateName === "media" ? I18n.t("island.media") : root.stateName === "critical" ? I18n.t("island.critical") : root.stateName === "progress" ? I18n.t("island.progress") : root.stateName === "device" ? I18n.t("island.device") : I18n.t("island.notification")
                    color: Tokens.textPrimary
                    font: Tokens.label
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Label {
                    visible: root.expanded
                    text: root.stateName === "authorization" ? I18n.t("island.authorization.detail") : root.stateName === "privacy" ? I18n.t("island.privacy.detail") : root.stateName === "media" ? I18n.t("island.media.detail") : root.stateName === "critical" ? I18n.t("island.critical.detail") : root.stateName === "progress" ? I18n.t("island.progress.detail") : root.stateName === "device" ? I18n.t("island.device.detail") : I18n.t("island.notification.detail")
                    color: Tokens.textSecondary
                    font: Tokens.caption
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Label {
                visible: root.stateName === "progress"
                text: "64%"
                color: Tokens.primary
                font: Tokens.label
            }
            IconButton {
                iconName: root.expanded ? "close" : "overview"
                text: I18n.t(root.expanded ? "island.collapse" : "island.expand")
                onClicked: root.expanded = !root.expanded
            }
        }
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.clicked()
        }
    }

    Timer {
        interval: root.eventPriority >= 6 ? 7000 : 4500
        running: !root.idle && !root.expanded && !Tokens.reducedMotion
        repeat: false
        onTriggered: root.returnToIdle()
    }
}
