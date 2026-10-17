// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Item {
    id: root
    readonly property var snapshot: Shell.state.snapshot
    readonly property bool compactHeight: height < Tokens.ambientCompactThreshold
    readonly property bool mediaVisible: height >= Tokens.ambientMediaThreshold
    readonly property real reservedHeight: !mediaVisible ? Tokens.ambientMinimalBudget : compactHeight ? Tokens.ambientCompactBudget : Tokens.ambientDetailsBudget
    ColumnLayout {
        objectName: "ambientComposition"
        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.space32, Tokens.settingsWidth)
        spacing: Tokens.space16
        DisplayClock {
            pixelSize: Math.max(Tokens.workingClockSize, Math.min((root.width - Tokens.space32) / 3.10, Tokens.ambientClockSize * Tokens.textScale, (root.height - root.reservedHeight) / Tokens.displayClockLineHeight))
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
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
            visible: !root.compactHeight
            text: root.snapshot.weather.available ? root.snapshot.weather.city + " · " + I18n.t("weather.condition." + root.snapshot.weather.condition) + "  " + I18n.number(root.snapshot.weather.temperature, 0) + "°" : I18n.t("friendly.weather.unavailable")
            font: Tokens.label
            color: Tokens.textSecondary
            Layout.alignment: Qt.AlignHCenter
        }
        TemporalCapsule {
            visible: !root.compactHeight
            compact: false
            showTime: false
            Layout.alignment: Qt.AlignHCenter
        }
        Rectangle {
            visible: root.mediaVisible
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
