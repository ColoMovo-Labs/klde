// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

LabPanel {
    id: root
    objectName: "systemUiGallery"
    heading: I18n.t("gallery.title")
    subtitle: I18n.t("gallery.subtitle")
    property string islandState: "idle"

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.space8
        ActionButton {
            text: I18n.t("gallery.idle")
            onClicked: root.islandState = "idle"
        }
        ActionButton {
            text: I18n.t("gallery.notification")
            onClicked: root.islandState = "notification"
        }
        ActionButton {
            text: I18n.t("gallery.progress")
            onClicked: root.islandState = "progress"
        }
        ActionButton {
            text: I18n.t("gallery.privacy")
            onClicked: root.islandState = "privacy"
        }
        ActionButton {
            text: I18n.t("gallery.auth")
            onClicked: root.islandState = "authorization"
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 96
        radius: Tokens.radiusXL
        color: Tokens.background
        SystemIsland {
            stateName: root.islandState
            anchors.centerIn: parent
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Tokens.space12
        columnSpacing: Tokens.space12
        Label {
            text: I18n.t("gallery.typography")
            font: Tokens.title
            color: Tokens.textPrimary
        }
        Label {
            text: "Display  ·  Headline  ·  Title  ·  Body  ·  Label  ·  Caption"
            font: Tokens.body
            color: Tokens.textSecondary
        }
        Label {
            text: I18n.t("gallery.surfaces")
            font: Tokens.title
            color: Tokens.textPrimary
        }
        RowLayout {
            Rectangle {
                width: 72
                height: 32
                radius: Tokens.radiusM
                color: Tokens.surfaceContainer
            }
            Rectangle {
                width: 72
                height: 32
                radius: Tokens.radiusL
                color: Tokens.primaryContainer
            }
            Rectangle {
                width: 72
                height: 32
                radius: Tokens.radiusPill
                color: Tokens.primary
            }
        }
        Label {
            text: I18n.t("gallery.states")
            font: Tokens.title
            color: Tokens.textPrimary
        }
        RowLayout {
            ActionButton {
                text: I18n.t("common.default")
            }
            ActionButton {
                text: I18n.t("common.selected")
                emphasized: true
            }
            ActionButton {
                text: I18n.t("common.disabled")
                enabled: false
            }
        }
        Label {
            text: I18n.t("gallery.system")
            font: Tokens.title
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.t("gallery.system-summary")
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
