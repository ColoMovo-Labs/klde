// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

Button {
    id: root
    property bool compact: true
    property bool showTime: true
    readonly property var reading: Shell.time.reading
    readonly property bool night: reading.phase === "starry-night" || reading.phase === "moonlit-night"
    readonly property bool rainy: reading.phase === "rainy-evening"
    readonly property bool cloudy: reading.weatherMood === "cloudy" || reading.weatherMood === "partly-cloudy" || rainy
    implicitWidth: compact ? Tokens.temporalWidth : Tokens.temporalRichWidth
    implicitHeight: compact ? Tokens.temporalHeight : Tokens.temporalRichHeight
    padding: Tokens.space8
    Accessible.name: reading.timeText + ", " + I18n.t("temporal.phase." + reading.phase) + ", " + I18n.t("temporal.season." + reading.season) + ", " + I18n.t(reading.weatherAvailable ? "weather.condition." + reading.weatherMood : "friendly.weather.unavailable")
    ToolTip.visible: hovered
    ToolTip.text: Accessible.name
    contentItem: RowLayout {
        spacing: Tokens.space8
        Item {
            id: scene
            Layout.preferredWidth: Tokens.temporalSceneSize
            Layout.preferredHeight: Tokens.temporalSceneSize
            clip: true
            Rectangle {
                width: parent.width
                height: parent.height
                radius: width / 2
                color: root.night ? Tokens.surfaceContainer : Tokens.primaryContainer
            }
            Rectangle {
                x: scene.width * 0.28
                y: root.reading.phase === "sunset" || root.rainy ? scene.height * 0.52 : scene.height * 0.18
                width: scene.width * 0.44
                height: width
                radius: width / 2
                color: root.night ? Tokens.secondary : root.reading.phase === "sunset" ? Tokens.tertiary : Tokens.primary
                Behavior on y {
                    enabled: root.visible && !Tokens.reducedMotion
                    NumberAnimation {
                        duration: Tokens.motionNormal
                    }
                }
                Behavior on color {
                    enabled: root.visible && !Tokens.reducedMotion
                    ColorAnimation {
                        duration: Tokens.motionNormal
                    }
                }
            }
            Rectangle {
                visible: root.night
                x: scene.width * 0.43
                y: scene.height * 0.10
                width: scene.width * 0.42
                height: width
                radius: width / 2
                color: Tokens.surfaceContainer
            }
            Rectangle {
                visible: root.cloudy && !root.night && root.reading.weatherAvailable
                x: scene.width * 0.10
                y: scene.height * 0.43
                width: scene.width * 0.70
                height: scene.height * 0.25
                radius: Tokens.radiusPill
                color: Tokens.outline
                opacity: Tokens.surfaceOpacityLow
            }
            Rectangle {
                x: Tokens.space6
                y: scene.height * 0.75
                width: scene.width - Tokens.space12
                height: Tokens.space1
                color: Tokens.outline
            }
            Row {
                visible: root.reading.phase === "starry-night" || root.rainy
                x: scene.width * 0.18
                y: root.rainy ? scene.height * 0.80 : scene.height * 0.17
                spacing: Tokens.space6
                Repeater {
                    model: 3
                    Rectangle {
                        width: Tokens.space2
                        height: root.rainy ? Tokens.space4 : Tokens.space2
                        radius: Tokens.radiusPill
                        color: Tokens.secondary
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.space2
            Label {
                visible: root.showTime
                text: root.reading.timeText
                color: Tokens.textPrimary
                font.family: Tokens.fontFamily
                font.pixelSize: (root.compact ? 26 : 32) * Tokens.textScale
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                visible: !root.compact || !root.showTime
                text: I18n.t("temporal.phase." + root.reading.phase)
                color: Tokens.textSecondary
                font: Tokens.caption
                Layout.alignment: Qt.AlignHCenter
            }
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.space4
                Repeater {
                    model: ["spring", "summer", "autumn", "winter"]
                    delegate: Rectangle {
                        required property string modelData
                        width: Tokens.temporalDot
                        height: width
                        radius: width / 2
                        color: modelData === root.reading.season ? Tokens.primary : Tokens.outline
                        opacity: modelData === root.reading.season ? 1 : Tokens.mutedOpacity
                    }
                }
            }
        }
    }
    background: Rectangle {
        radius: Tokens.radiusXL
        color: root.hovered || root.down ? Tokens.primaryContainer : Tokens.surface
        border.width: root.visualFocus ? Tokens.space2 : Tokens.space1
        border.color: root.visualFocus ? Tokens.primary : Qt.rgba(Tokens.outline.r, Tokens.outline.g, Tokens.outline.b, Tokens.outlineOpacity)
    }
}
