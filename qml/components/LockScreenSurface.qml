// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

// Full-surface visual study only. It is deliberately not a session lock and
// never owns authentication credentials or a privileged helper.
Item {
    id: root
    required property string stateName
    readonly property bool authentication: stateName === "auth" || stateName === "error" || stateName === "reduced"
    readonly property bool errorState: stateName === "error"
    readonly property bool reducedMotion: stateName === "reduced" || Tokens.reducedMotion
    readonly property bool depthState: stateName === "depth"
    readonly property bool fallbackState: stateName === "fallback"
    readonly property var snapshot: Shell.state.snapshot
    readonly property var effects: Shell.wallpaperEffects.state
    focus: true
    clip: true
    Component.onCompleted: forceActiveFocus()
    Keys.onReturnPressed: if (!root.authentication)
        root.stateName = "auth"
    Keys.onEscapePressed: if (root.authentication)
        root.stateName = "ambient"

    Rectangle {
        anchors.fill: parent
        color: Tokens.background
    }
    WallpaperLayers {
        anchors.fill: parent
        lockPreview: true
    }
    Image {
        anchors.fill: parent
        visible: root.depthState && root.effects.foregroundAsset.length > 0
        source: visible ? root.effects.foregroundAsset : ""
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectCrop
        scale: 1 + [0, Tokens.depthLow, Tokens.depthMedium, Tokens.depthHigh][root.effects.depthTier]
    }
    Rectangle {
        anchors.fill: parent
        color: Tokens.darkMode ? "#3210182b" : "#22ffffff"
    }

    Item {
        id: ambientComposition
        visible: !root.authentication
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Tokens.space24
        width: Math.min(parent.width - Tokens.lockScreenEdgeMargin * 2, 720)
        height: ambientStack.height
        Column {
            id: ambientStack
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.space12
            DisplayClock {
                id: lockClock
                objectName: "lockAmbientClock"
                anchors.horizontalCenter: parent.horizontalCenter
                pixelSize: Math.min(204, Math.max(144, root.height * 0.18))
            }
            Label {
                id: lockDate
                objectName: "lockAmbientDate"
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.date(root.snapshot.time, false)
                color: Tokens.textPrimary
                font: Tokens.title
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.depthState ? I18n.t("lock.depth") : root.fallbackState ? I18n.t("lock.fallback") : I18n.t("lock.mock")
                color: Tokens.textSecondary
                font: Tokens.caption
            }
        }
    }

    Label {
        objectName: "lockEnvironment"
        visible: !root.authentication
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.lockScreenEdgeMargin
        anchors.bottomMargin: Tokens.lockScreenEdgeMargin
        text: root.snapshot.weather.available ? root.snapshot.weather.city + " · " + I18n.t("weather.condition." + root.snapshot.weather.condition) + "  " + I18n.number(root.snapshot.weather.temperature, 0) + "°" : I18n.t("friendly.weather.unavailable")
        color: Tokens.textSecondary
        font: Tokens.label
    }

    Surface {
        id: authPanel
        objectName: "lockAuthenticationPanel"
        visible: root.authentication
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Tokens.space8
        width: Math.min(Tokens.lockScreenContentWidth, parent.width - Tokens.lockScreenEdgeMargin * 2)
        height: authColumn.implicitHeight + Tokens.space32 * 2
        padding: Tokens.space32
        cornerRadius: Tokens.radiusXL
        tone: Tokens.surfaceElevated
        ColumnLayout {
            id: authColumn
            anchors.fill: parent
            spacing: Tokens.space12
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.space12
                Rectangle {
                    Layout.preferredWidth: Tokens.iconL
                    Layout.preferredHeight: Tokens.iconL
                    radius: width / 2
                    color: Tokens.primaryContainer
                    Label {
                        anchors.centerIn: parent
                        text: "C"
                        color: Tokens.primary
                        font: Tokens.headline
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: I18n.t("lock.user")
                        color: Tokens.textPrimary
                        font: Tokens.title
                    }
                    Label {
                        text: I18n.t("lock.mock-auth")
                        color: Tokens.textSecondary
                        font: Tokens.caption
                    }
                }
            }
            TextField {
                id: passwordField
                objectName: "lockPasswordField"
                Layout.fillWidth: true
                readOnly: true
                placeholderText: I18n.t("lock.password")
                echoMode: TextInput.Password
                font: Tokens.body
                background: Rectangle {
                    radius: Tokens.radiusM
                    color: Tokens.surfaceContainer
                    border.width: passwordField.visualFocus ? Tokens.space2 : Tokens.capsuleBorderWidth
                    border.color: passwordField.visualFocus ? Tokens.primary : Tokens.outline
                }
            }
            Label {
                visible: root.errorState
                objectName: "lockError"
                Layout.fillWidth: true
                text: I18n.t("lock.error")
                color: Tokens.error
                font: Tokens.label
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: I18n.t("lock.input") + " · 中"
                    color: Tokens.textSecondary
                    font: Tokens.caption
                    Layout.fillWidth: true
                }
                IconButton {
                    iconName: "info"
                    text: I18n.t("lock.accessibility")
                }
                IconButton {
                    iconName: "settings"
                    text: I18n.t("lock.session")
                }
            }
            ActionButton {
                Layout.fillWidth: true
                text: root.errorState ? I18n.t("lock.try-again") : I18n.t("lock.unlock")
                emphasized: true
                onClicked: root.stateName = "error"
            }
        }
    }

    Row {
        visible: root.authentication
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Tokens.lockScreenEdgeMargin
        anchors.bottomMargin: Tokens.lockScreenEdgeMargin
        spacing: Tokens.space8
        IconButton {
            iconName: "power"
            text: I18n.t("lock.power")
        }
    }

    Label {
        visible: root.authentication
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space24
        text: I18n.t("lock.disclosure")
        color: Tokens.textSecondary
        font: Tokens.caption
    }

    GeometryDebugOverlay {
        anchors.fill: parent
        enabled: Tokens.debugGeometry
        targetItems: root.authentication ? [authPanel, passwordField] : [ambientComposition, lockClock, lockDate]
        contentItems: root.authentication ? [authColumn] : [ambientStack]
        textItems: root.authentication ? [lockError] : [lockDate]
    }
}
