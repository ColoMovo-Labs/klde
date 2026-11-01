// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

LabPanel {
    id: root
    objectName: "notificationCenter"
    heading: I18n.t("lab.center.title")
    subtitle: I18n.date(Shell.state.snapshot.time, false)
    property int tab: Shell.notifications.native ? 1 : 0
    property string focusedNotificationId: ""
    signal weatherRequested
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: ["lab.center.info", "lab.center.notifications", "lab.center.weather"]
            delegate: ActionButton {
                required property string modelData
                required property int index
                visible: !(Shell.notifications.native && index === 0)
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
                        text: "Mori · " + Branding.displayName + " Studio"
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
            visible: Shell.notifications.native && !Shell.notifications.available
            text: I18n.t("notification.service.readonly")
            font: Tokens.body
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Label {
            visible: Shell.notifications.count === 0
            text: I18n.t("friendly.notifications.empty")
            font: Tokens.body
            color: Tokens.textSecondary
        }
        Repeater {
            model: Shell.notifications
            delegate: ColumnLayout {
                id: record
                required property string notificationId
                required property string sourceName
                required property string titleId
                required property string bodyId
                required property string titleText
                required property string bodyMarkup
                required property string notificationIcon
                required property var notificationActions
                required property int severity
                required property bool demo
                required property bool groupStart
                Layout.fillWidth: true
                Label {
                    visible: !record.demo && record.groupStart
                    text: record.sourceName
                    textFormat: Text.PlainText
                    font: Tokens.label
                    color: Tokens.textSecondary
                }
                NotificationCardForm {
                    id: card
                    Layout.fillWidth: true
                    sourceName: record.sourceName
                    showSource: record.demo
                    heading: record.demo ? I18n.t(record.titleId) : record.titleText
                    body: record.demo ? I18n.t(record.bodyId) : record.bodyMarkup
                    bodyFormat: record.demo ? Text.PlainText : Text.RichText
                    iconName: record.notificationIcon
                    severity: record.severity
                    highlighted: root.focusedNotificationId === record.notificationId
                    onHighlightedChanged: if (highlighted)
                        Qt.callLater(() => root.ensureVisible(record))
                    Connections {
                        target: card.dismissButton
                        function onClicked(): void {
                            Shell.notifications.dismiss(record.notificationId);
                        }
                    }
                    Connections {
                        target: card.bodyLabel
                        function onLinkActivated(link: string): void {
                            if (/^(https?:|mailto:)/i.test(link))
                                Qt.openUrlExternally(link);
                        }
                    }
                }
                Flow {
                    visible: record.notificationActions.length > 0
                    Layout.fillWidth: true
                    spacing: Tokens.space8
                    Repeater {
                        model: record.notificationActions
                        delegate: ActionButton {
                            required property var modelData
                            text: modelData.label
                            onClicked: Shell.notifications.invokeAction(record.notificationId, modelData.key)
                        }
                    }
                }
            }
        }
    }
    ColumnLayout {
        visible: root.tab === 2
        Layout.fillWidth: true
        Label {
            text: Shell.weather.available ? I18n.number(Shell.weather.temperature, 0) + "°" : "—"
            font: Tokens.display
            color: Tokens.primary
        }
        Label {
            text: Shell.weather.available ? I18n.t(Shell.weather.conditionId) : I18n.t("friendly.weather.unavailable")
            font: Tokens.title
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.s(Shell.weatherService.attribution)
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
    footer: Shell.notifications.native ? null : mockFooter
    Component {
        id: mockFooter
        Rectangle {
            visible: !Shell.notifications.native
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
}
