// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Item {
    id: root
    readonly property var snapshot: Shell.state.snapshot
    readonly property bool focusMode: snapshot.appearance.focus
    readonly property bool detailsVisible: !focusMode && height >= Tokens.ambientMediaThreshold && height >= Tokens.ambientMediaMinimumHeight
    ColumnLayout {
        objectName: "ambientComposition"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(0, (root.height - height) / 2 - (root.detailsVisible ? Tokens.space32 : 0))
        width: Math.min(parent.width - Tokens.space32, Tokens.settingsWidth)
        spacing: Tokens.space16
        DisplayClock {
            pixelSize: Math.max(Tokens.workingClockSize, Math.min((root.width - Tokens.space32) / (Tokens.displayClockDigitWidth * 4 + Tokens.displayClockColonWidth), Tokens.ambientClockSize * Tokens.textScale, root.height * 0.48))
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
    }
    Label {
        objectName: "ambientWeather"
        visible: root.detailsVisible
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.space16
        width: parent.width * 0.42
        text: root.snapshot.weather.available ? root.snapshot.weather.city + " · " + I18n.t("weather.condition." + root.snapshot.weather.condition) + "  " + I18n.number(root.snapshot.weather.temperature, 0) + "°" : I18n.t("friendly.weather.unavailable")
        font: Tokens.label
        color: Tokens.textSecondary
        wrapMode: Text.WordWrap
    }
    Rectangle {
        objectName: "ambientMediaCard"
        visible: root.detailsVisible
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.space16
        width: Math.min(Tokens.temporalExpandedWidth, parent.width * 0.48)
        height: media.implicitHeight + Tokens.space24
        color: Tokens.primaryContainer
        radius: Tokens.radiusL
        ColumnLayout {
            id: media
            anchors.centerIn: parent
            width: parent.width - Tokens.space24
            spacing: Tokens.space8
            Label {
                text: I18n.t("lab.media.track") + " · " + root.snapshot.media.artist
                color: Tokens.textPrimary
                font: Tokens.label
                elide: Text.ElideRight
                Layout.fillWidth: true
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
