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
    property var notificationSource: Shell.notifications
    property bool notificationsEnabled: true
    property real maximumWidth: Tokens.settingsWidth
    property bool displayingNotification: false
    readonly property var incomingNotification: notificationSource ? notificationSource.popup : ({})
    property var notification: ({})
    readonly property bool gentleMotion: Tokens.reducedMotion || !Shell.blur.renderingAllowed
    readonly property real restingWidth: capsule.implicitWidth
    readonly property real restingHeight: capsule.implicitHeight
    readonly property real cornerRadius: displayingNotification ? Tokens.radiusXL : height / 2
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
    signal notificationActivated(string notificationId)
    function syncNotification(): void {
        if (!notificationsEnabled || !incomingNotification.id) {
            if (notificationSource && notificationSource.locked)
                notification = ({});
            if (displayingNotification)
                returnToIdle();
            return;
        }
        const priority = incomingNotification.severity === 2 ? 8 : 2;
        if (!displayingNotification && eventPriority > priority) {
            notificationSource.pausePopup(true);
            return;
        }
        notification = incomingNotification;
        if (!displayingNotification)
            requestState(notification.severity === 2 ? "critical" : "notification", priority);
        else
            stateName = notification.severity === 2 ? "critical" : "notification";
        displayingNotification = true;
        expanded = true;
        notificationSource.pausePopup(notificationHover.hovered);
    }
    onIncomingNotificationChanged: Qt.callLater(syncNotification)
    onNotificationsEnabledChanged: Qt.callLater(syncNotification)
    onStateNameChanged: Qt.callLater(syncNotification)
    Component.onCompleted: syncNotification()

    function requestState(nextState: string, priority: int): bool {
        if (priority < eventPriority)
            return false;
        displayingNotification = false;
        stateName = nextState;
        expanded = false;
        return true;
    }

    function returnToIdle(): void {
        displayingNotification = false;
        stateName = "idle";
        expanded = false;
    }

    implicitWidth: displayingNotification ? Math.min(maximumWidth, Tokens.settingsWidth) : idle ? capsule.implicitWidth : expanded ? 320 : 236
    implicitHeight: displayingNotification ? notificationContent.implicitHeight + Tokens.space32 : idle ? capsule.implicitHeight : expanded ? 80 : 48
    width: implicitWidth
    height: implicitHeight
    Behavior on width {
        enabled: !root.gentleMotion
        NumberAnimation {
            duration: Tokens.springSpatial.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Tokens.springSpatial.curve
        }
    }
    Behavior on height {
        enabled: !root.gentleMotion
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
        visible: !root.idle && !root.displayingNotification
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

    Surface {
        id: notificationSurface
        objectName: "notificationIsland"
        Accessible.role: Accessible.AlertMessage
        Accessible.ignored: !root.displayingNotification
        Accessible.name: root.notification.demo ? I18n.t(root.notification.titleId) : root.notification.title || ""
        Accessible.description: root.notification.demo ? I18n.t(root.notification.bodyId) : root.notification.body || ""
        visible: root.displayingNotification || opacity > 0
        opacity: root.displayingNotification ? 1 : 0
        anchors.fill: parent
        padding: Tokens.space16
        material: "glass"
        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.motionFade
            }
        }
        HoverHandler {
            id: notificationHover
            onHoveredChanged: if (root.displayingNotification)
                root.notificationSource.pausePopup(hovered)
        }
        ColumnLayout {
            id: notificationContent
            anchors.fill: parent
            spacing: Tokens.space8
            NotificationCardForm {
                id: notificationCard
                Layout.fillWidth: true
                decorationVisible: false
                iconName: root.notification.icon || "bell"
                sourceName: root.notification.source || ""
                heading: root.notification.demo ? I18n.t(root.notification.titleId) : root.notification.title || ""
                body: root.notification.demo ? I18n.t(root.notification.bodyId) : root.notification.body || ""
                bodyMaximumLines: 1
                severity: root.notification.severity || 0
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: Tokens.controlHeight + Tokens.space16
                    onClicked: {
                        const id = root.notification.id;
                        root.notificationActivated(id);
                        root.notificationSource.advancePopup();
                    }
                }
                Connections {
                    target: notificationCard.dismissButton
                    function onClicked(): void {
                        root.notificationSource.dismiss(root.notification.id);
                    }
                }
            }
            Flow {
                visible: (root.notification.actions || []).length > 0
                Layout.fillWidth: true
                spacing: Tokens.space8
                Repeater {
                    model: root.notification.actions || []
                    delegate: ActionButton {
                        required property var modelData
                        text: modelData.label
                        onClicked: root.notificationSource.invokeAction(root.notification.id, modelData.key)
                    }
                }
            }
        }
    }

    Timer {
        interval: root.eventPriority >= 6 ? 7000 : 4500
        running: !root.idle && !root.expanded && !root.displayingNotification && !Tokens.reducedMotion
        repeat: false
        onTriggered: root.returnToIdle()
    }
}
