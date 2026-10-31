// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "quickSettingsForm"
    width: Tokens.panelWidth - Tokens.space32
    height: column.implicitHeight
    implicitHeight: column.implicitHeight
    property alias closeButton: closeButton
    property alias settingsButton: settingsButton
    property alias powerButton: powerButton
    property alias wifiButton: wifiButton
    property alias bluetoothButton: bluetoothButton
    property alias nightButton: nightButton
    property alias motionButton: motionButton
    property alias dndButton: dndButton
    property alias microphoneButton: microphoneButton
    property alias brightnessSlider: brightnessSlider
    property alias volumeSlider: volumeSlider
    property alias microphoneSlider: microphoneSlider
    property alias profileChoice: profileChoice
    property alias moreButton: moreButton
    property bool wifiOn: true
    property bool bluetoothOn: true
    property bool nightOn: false
    property bool quietOn: false
    property bool dndOn: false
    property bool microphoneOn: true
    property bool bluetoothAvailable: true
    property bool microphoneAvailable: true
    property bool brightnessAvailable: true
    property string wifiDetail: "Snowline_5G"
    property string provenance: "模拟系统数据 / Mock system data"
    property string wifiLabel: "Wi-Fi"
    property string bluetoothLabel: "蓝牙 / Bluetooth"
    property string dndLabel: "勿扰 / Do not disturb"
    property string nightLabel: "夜间模式 / Night light"
    property string motionLabel: "轻缓动效 / Reduced motion"
    property string microphoneLabel: "麦克风 / Microphone"
    property string brightnessLabel: "亮度 / Brightness"
    property string volumeLabel: "音量 / Volume"
    property string settingsLabel: "设置 / Settings"
    property string powerLabel: "电源 / Power"
    property var profileLabels: ["性能", "均衡", "节能"]
    ColumnLayout {
        id: column
        width: parent.width
        spacing: Tokens.space12
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.provenance
                font: Tokens.caption
                color: Tokens.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            SmallButton {
                id: settingsButton
                iconName: "settings"
                text: root.settingsLabel
            }
            SmallButton {
                id: powerButton
                iconName: "power"
                text: root.powerLabel
            }
            SmallButton {
                id: closeButton
                iconName: "close"
                text: "关闭 / Close"
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space8
            uniformCellSizes: true
            Button {
                id: wifiButton
                objectName: "quickWifi"
                Layout.fillWidth: true
                implicitHeight: Tokens.compactToggleHeight
                Accessible.name: root.wifiLabel + ", " + root.wifiDetail
                background: Rectangle {
                    radius: Tokens.radiusL
                    color: root.wifiOn ? Tokens.primaryContainer : Tokens.surfaceContainer
                    border.width: wifiButton.visualFocus ? 2 : 0
                    border.color: Tokens.primary
                }
                contentItem: RowLayout {
                    Glyph {
                        name: "wifi"
                        Layout.preferredWidth: Tokens.iconM
                        Layout.preferredHeight: Tokens.iconM
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: Tokens.space4
                        Text {
                            text: root.wifiLabel
                            font: Tokens.label
                            color: Tokens.textPrimary
                        }
                        Text {
                            width: parent.width
                            text: root.wifiDetail
                            textFormat: Text.PlainText
                            font: Tokens.caption
                            color: Tokens.textSecondary
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            Button {
                id: bluetoothButton
                objectName: "quickBluetooth"
                enabled: root.bluetoothAvailable
                Layout.fillWidth: true
                implicitHeight: Tokens.compactToggleHeight
                Accessible.name: root.bluetoothLabel
                background: Rectangle {
                    radius: Tokens.radiusL
                    color: root.bluetoothOn ? Tokens.primaryContainer : Tokens.surfaceContainer
                    border.width: bluetoothButton.visualFocus ? 2 : 0
                    border.color: Tokens.primary
                }
                contentItem: RowLayout {
                    Glyph {
                        name: "bluetooth"
                        Layout.preferredWidth: Tokens.iconM
                        Layout.preferredHeight: Tokens.iconM
                    }
                    Text {
                        text: root.bluetoothLabel
                        font: Tokens.label
                        color: Tokens.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.space8
            SmallButton {
                id: nightButton
                toggle: true
                objectName: "quickNight"
                Layout.fillWidth: true
                iconName: "moon"
                text: root.nightLabel
                selected: root.nightOn
            }
            SmallButton {
                id: motionButton
                toggle: true
                objectName: "quickMotion"
                Layout.fillWidth: true
                iconName: "leaf"
                text: root.motionLabel
                selected: root.quietOn
            }
            SmallButton {
                id: dndButton
                toggle: true
                objectName: "quickDnd"
                Layout.fillWidth: true
                iconName: "bell"
                text: root.dndLabel
                selected: root.dndOn
                Accessible.description: root.dndOn ? "On" : "Off"
            }
            SmallButton {
                id: microphoneButton
                toggle: true
                objectName: "quickMicrophone"
                Layout.fillWidth: true
                iconName: "microphone"
                text: root.microphoneLabel
                selected: root.microphoneOn
                enabled: root.microphoneAvailable
            }
        }
        CompactSliderForm {
            id: brightnessSlider
            visible: root.brightnessAvailable
            Layout.fillWidth: true
            label: root.brightnessLabel
            glyph: "sun"
            value: 73
        }
        CompactSliderForm {
            id: volumeSlider
            Layout.fillWidth: true
            label: root.volumeLabel
            glyph: "volume"
            value: 77
        }
        CompactSliderForm {
            id: microphoneSlider
            visible: root.microphoneAvailable
            Layout.fillWidth: true
            label: root.microphoneLabel
            glyph: "microphone"
            value: 85
        }
        ComboBox {
            id: profileChoice
            objectName: "quickPowerProfile"
            Layout.fillWidth: true
            model: root.profileLabels
            currentIndex: 1
            Accessible.name: "电源模式 / Power profile"
            font: Tokens.label
            implicitHeight: Tokens.controlHeight
            background: Rectangle {
                radius: Tokens.radiusM
                color: Tokens.surfaceContainer
                border.width: profileChoice.visualFocus ? Tokens.space2 : 0
                border.color: Tokens.primary
            }
            contentItem: Text {
                text: profileChoice.currentText
                font: Tokens.label
                color: Tokens.textPrimary
                verticalAlignment: Text.AlignVCenter
                leftPadding: Tokens.space12
                rightPadding: Tokens.space32
                elide: Text.ElideRight
            }
            indicator: Glyph {
                name: "next"
                rotation: 90
                x: profileChoice.width - width - Tokens.space12
                anchors.verticalCenter: parent.verticalCenter
            }
            palette.text: Tokens.textPrimary
            palette.buttonText: Tokens.textPrimary
            palette.highlight: Tokens.primaryContainer
            palette.highlightedText: Tokens.textPrimary
        }
        SmallButton {
            id: moreButton
            objectName: "quickMore"
            Layout.alignment: Qt.AlignRight
            iconName: "grid"
            text: "更多设置 / More settings"
        }
    }
}
