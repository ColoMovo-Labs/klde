// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "notificationCenter"
    heading: I18n.t("lab.center.title")
    subtitle: I18n.date(Shell.state.snapshot.time, false)
    property int tab: 0
    signal weatherRequested
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: ["lab.center.info", "lab.center.notifications", "lab.center.weather"]
            delegate: ActionButton {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                text: I18n.t(modelData)
                emphasized: index === root.tab
                onClicked: root.tab = index
            }
        }
    }
    Rectangle {
        visible: root.tab === 0
        Layout.fillWidth: true
        implicitHeight: profileColumn.implicitHeight + Tokens.space32
        radius: Tokens.radiusXL
        color: Tokens.primaryContainer
        ColumnLayout {
            id: profileColumn
            anchors.fill: parent
            anchors.margins: Tokens.space16
            RowLayout {
                Icon {
                    name: "klde"
                    Layout.preferredWidth: Tokens.dockItem
                    Layout.preferredHeight: Tokens.dockItem
                }
                ColumnLayout {
                    Label {
                        text: "Mori · KLDE Studio"
                        font: Tokens.title
                        color: Tokens.textPrimary
                    }
                    Label {
                        text: I18n.t("lab.center.profile")
                        font: Tokens.caption
                        color: Tokens.textSecondary
                    }
                }
            }
            Label {
                text: I18n.t("lab.center.system")
                font: Tokens.label
                color: Tokens.textPrimary
            }
            Label {
                visible: Shell.state.snapshot.updateAvailable
                text: I18n.t("lab.notification.update.title")
                font: Tokens.label
                color: Tokens.primary
            }
            Label {
                text: I18n.t("lab.preview")
                font: Tokens.caption
                color: Tokens.textSecondary
            }
        }
    }
    ColumnLayout {
        visible: root.tab !== 2
        Layout.fillWidth: true
        spacing: Tokens.rowGap
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: I18n.t("lab.center.count").arg(Shell.notifications.count)
                font: Tokens.label
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            ActionButton {
                objectName: "clearNotifications"
                text: I18n.t("lab.center.clear")
                enabled: Shell.notifications.count > 0
                onClicked: Shell.notifications.clearAll()
            }
        }
        Label {
            visible: Shell.notifications.count === 0
            text: I18n.t("friendly.notifications.empty")
            font: Tokens.body
            color: Tokens.textSecondary
        }
        Repeater {
            model: Shell.notifications
            delegate: Rectangle {
                id: card
                required property string notificationId
                required property string sourceName
                required property string titleId
                required property string bodyId
                required property int severity
                Layout.fillWidth: true
                implicitHeight: notificationColumn.implicitHeight + Tokens.space24
                radius: severity === 2 ? Tokens.radiusM : Tokens.radiusL
                color: severity === 2 ? Qt.tint(Tokens.surfaceContainer, Qt.rgba(Tokens.error.r, Tokens.error.g, Tokens.error.b, 0.12)) : Tokens.surfaceContainer
                border.width: severity === 2 ? Tokens.space1 : 0
                border.color: Tokens.error
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.space12
                    Icon {
                        name: card.severity === 2 ? "info" : "bell"
                        Layout.preferredWidth: Tokens.iconM
                        Layout.preferredHeight: Tokens.iconM
                    }
                    ColumnLayout {
                        id: notificationColumn
                        Layout.fillWidth: true
                        spacing: Tokens.space4
                        Label {
                            text: card.sourceName
                            font: Tokens.caption
                            color: Tokens.textSecondary
                        }
                        Label {
                            text: I18n.t(card.titleId)
                            font: Tokens.label
                            color: card.severity === 2 ? Tokens.error : Tokens.textPrimary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            text: I18n.t(card.bodyId)
                            font: Tokens.body
                            color: Tokens.textSecondary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                    IconButton {
                        iconName: "close"
                        text: I18n.t("lab.center.dismiss")
                        onClicked: Shell.notifications.dismiss(card.notificationId)
                    }
                }
            }
        }
    }
    ColumnLayout {
        visible: root.tab === 2
        Layout.fillWidth: true
        Label {
            text: Shell.state.snapshot.weather.available ? I18n.number(Shell.state.snapshot.weather.temperature, 0) + "°" : "—"
            font: Tokens.display
            color: Tokens.primary
        }
        Label {
            text: I18n.t("weather.condition." + Shell.state.snapshot.weather.condition)
            font: Tokens.title
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.t(Shell.state.snapshot.weather.available ? "lab.weather.mock" : "friendly.weather.unavailable")
            font: Tokens.body
            color: Tokens.textSecondary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        ActionButton {
            text: I18n.t("lab.weather.settings")
            onClicked: root.weatherRequested()
        }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Tokens.controlHeight + Tokens.space16
        radius: Tokens.radiusPill
        color: Tokens.primaryContainer
        Label {
            anchors.centerIn: parent
            text: I18n.t("lab.center.tasks")
            font: Tokens.label
            color: Tokens.textPrimary
        }
    }
}
