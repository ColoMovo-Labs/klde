// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Tokens.background
    readonly property var phases: ["clear-morning", "cloudy-day", "sunset", "rainy-evening", "starry-night", "moonlit-night"]
    function fixture(phase: string): var {
        const index = phases.indexOf(phase);
        return {
            phase: phase,
            timeText: ["07:12", "14:26", "18:08", "18:42", "22:16", "01:24"][index],
            season: "autumn",
            mock: true,
            sunVisible: index < 3,
            moonVisible: index === 5,
            sunX: index === 2 ? 0.29 : 0.23,
            sunY: index === 2 ? 0.66 : 0.35,
            moonX: 0.26,
            moonY: 0.35
        };
    }
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.space32 * 2, Tokens.temporalStudyWidth)
        spacing: Tokens.space24
        Label {
            text: I18n.t("temporal.study.title")
            font: Tokens.headline
            color: Tokens.textPrimary
        }
        Label {
            text: I18n.t("temporal.mock")
            font: Tokens.body
            color: Tokens.textSecondary
        }
        GridLayout {
            columns: 3
            columnSpacing: Tokens.space16
            rowSpacing: Tokens.space16
            Layout.fillWidth: true
            Repeater {
                model: root.phases
                delegate: Rectangle {
                    id: sceneCell
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: Tokens.temporalStudyCardHeight
                    radius: Tokens.radiusL
                    color: Tokens.surface
                    border.width: Tokens.space1
                    border.color: Tokens.surfaceEdge
                    Column {
                        anchors.centerIn: parent
                        spacing: Tokens.space16
                        Label {
                            text: I18n.t("temporal.phase." + sceneCell.modelData)
                            color: Tokens.textSecondary
                            font: Tokens.label
                        }
                        TemporalCapsule {
                            readingOverride: root.fixture(sceneCell.modelData)
                        }
                    }
                }
            }
        }
        Label {
            text: I18n.t("temporal.study.sizes")
            font: Tokens.title
            color: Tokens.textPrimary
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space24
            Repeater {
                model: ["compact", "standard", "expanded"]
                delegate: ColumnLayout {
                    id: sizeCell
                    required property string modelData
                    Layout.fillWidth: true
                    spacing: Tokens.space16
                    Label {
                        text: I18n.t("temporal.size." + sizeCell.modelData)
                        font: Tokens.label
                        color: Tokens.textSecondary
                    }
                    TemporalCapsule {
                        sizeMode: sizeCell.modelData
                        readingOverride: root.fixture("sunset")
                    }
                }
            }
        }
    }
}
