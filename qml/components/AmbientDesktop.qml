// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Item {
    id: root
    readonly property var snapshot: Shell.state.snapshot
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.space32, Tokens.settingsWidth)
        spacing: Tokens.space16
        Label {
            text: Qt.formatTime(new Date(root.snapshot.time), "hh:mm")
            font.family: Tokens.fontFamily
            font.pixelSize: Math.min(root.width / 3.5, Tokens.ambientClockSize) * Tokens.textScale
            font.weight: Font.Medium
            color: Tokens.primary
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            text: I18n.date(root.snapshot.time, false)
            font: Tokens.title
            color: Tokens.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            objectName: "ambientWeather"
            text: root.snapshot.weather.available ? root.snapshot.weather.city + " · " + I18n.t("weather.condition." + root.snapshot.weather.condition) + "  " + I18n.number(root.snapshot.weather.temperature, 0) + "°" : I18n.t("friendly.weather.unavailable")
            font: Tokens.label
            color: Tokens.textSecondary
            Layout.alignment: Qt.AlignHCenter
        }
        Rectangle {
            Layout.topMargin: Tokens.space24
            Layout.fillWidth: true
            implicitHeight: Tokens.sceneCardHeight + Tokens.space16
            color: Tokens.primaryContainer
            radius: Tokens.radiusXL
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.space16
                Label {
                    text: I18n.t("lab.media.track")
                    color: Tokens.textPrimary
                    font: Tokens.title
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: root.snapshot.media.artist
                    color: Tokens.textSecondary
                    font: Tokens.caption
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    ActionButton {
                        text: "◀"
                        Accessible.name: I18n.t("lab.media.previous")
                        onClicked: Shell.showNotice(I18n.t("lab.media.track"))
                    }
                    ActionButton {
                        text: I18n.t(root.snapshot.media.playing ? "lab.media.pause" : "lab.media.play")
                        emphasized: true
                        onClicked: Shell.previewAction("shell.media")
                    }
                    ActionButton {
                        text: "▶"
                        Accessible.name: I18n.t("lab.media.next")
                        onClicked: Shell.showNotice(I18n.t("lab.media.track"))
                    }
                }
            }
        }
    }
}
