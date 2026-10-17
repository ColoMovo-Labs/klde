// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

LabPanel {
    heading: I18n.t("lab.apps.title")
    subtitle: I18n.t("lab.apps.disclosure")
    Repeater {
        model: [
            {
                id: "files",
                name: "Lingmo File Manager / Peony"
            },
            {
                id: "terminal",
                name: "QTerminal / Lingmo Terminal"
            },
            {
                id: "settings",
                name: "KLDE / Lingmo Settings"
            },
            {
                id: "images",
                name: "Lingmo Album"
            },
            {
                id: "editor",
                name: "Lingmo Text Editor"
            },
            {
                id: "screenshot",
                name: "UKUI Screenshot / Spectacle"
            },
            {
                id: "calculator",
                name: "Lingmo / Cutefish Calculator"
            },
            {
                id: "archive",
                name: "Engrampa / UKUI archive tools"
            },
            {
                id: "software",
                name: "Discover / distribution software tools"
            },
            {
                id: "media",
                name: "Lingmo Video Player / mpv"
            }
        ]
        delegate: Rectangle {
            id: appCard
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Tokens.launcherRow + Tokens.space16
            radius: Tokens.radiusL
            color: Tokens.surfaceContainer
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.space12
                Label {
                    text: I18n.t("lab.apps." + appCard.modelData.id)
                    font: Tokens.label
                    color: Tokens.primary
                }
                Label {
                    text: appCard.modelData.name
                    font: Tokens.body
                    color: Tokens.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }
}
