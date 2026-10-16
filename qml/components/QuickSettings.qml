// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "quickSettings"
    signal blurRequested
    width: Tokens.panelWidth
    height: Math.min(settingsColumn.implicitHeight + padding * 2, parent ? parent.height - y - Tokens.space24 : Tokens.previewHeight)
    contentItem: ScrollView {
        id: scroller
        clip: true
        contentWidth: availableWidth
        ColumnLayout {
            id: settingsColumn
            width: scroller.availableWidth
            spacing: Tokens.space16
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.space4
                    Label {
                        text: qsTr("Your little controls.")
                        font: Tokens.title
                        color: Tokens.textPrimary
                    }
                    Label {
                        text: qsTr("Preview · mock system state")
                        font: Tokens.caption
                        color: Tokens.textSecondary
                    }
                }
                IconButton {
                    iconName: "close"
                    text: qsTr("Close quick settings")
                    onClicked: root.close()
                }
            }
            GridLayout {
                columns: 2
                columnSpacing: Tokens.space12
                rowSpacing: Tokens.space12
                Layout.fillWidth: true
                ToggleTile {
                    text: qsTr("Wi-Fi")
                    iconName: "wifi"
                    selected: Shell.system.wifi
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.wifi = !Shell.system.wifi
                }
                ToggleTile {
                    text: qsTr("Bluetooth")
                    iconName: "bluetooth"
                    selected: Shell.system.bluetooth
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.bluetooth = !Shell.system.bluetooth
                }
                ToggleTile {
                    text: qsTr("Night light")
                    iconName: "moon"
                    selected: Shell.system.nightMode
                    Layout.fillWidth: true
                    onToggleRequested: Shell.system.nightMode = !Shell.system.nightMode
                }
                ToggleTile {
                    text: qsTr("Quiet motion")
                    iconName: "leaf"
                    selected: Tokens.reducedMotion
                    Layout.fillWidth: true
                    onToggleRequested: Tokens.reducedMotion = !Tokens.reducedMotion
                }
            }
            SliderCard {
                label: qsTr("Brightness")
                iconName: "sun"
                value: Shell.system.brightness
                Layout.fillWidth: true
                onValueRequested: requestedValue => Shell.system.brightness = requestedValue
            }
            SliderCard {
                label: qsTr("Volume")
                iconName: "volume"
                value: Shell.system.volume
                Layout.fillWidth: true
                onValueRequested: requestedValue => Shell.system.volume = requestedValue
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: qsTr("Power profile")
                    font: Tokens.label
                    color: Tokens.textPrimary
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["Balanced", "Power saver", "Performance"]
                    currentIndex: model.indexOf(Shell.system.powerProfile)
                    Accessible.name: qsTr("Power profile")
                    onActivated: Shell.system.powerProfile = currentText
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Switch {
                    text: qsTr("Dark")
                    checked: Tokens.darkMode
                    onToggled: Tokens.darkMode = checked
                    font: Tokens.label
                }
                Switch {
                    text: qsTr("Shadows")
                    checked: Tokens.shadowsEnabled
                    onToggled: Tokens.shadowsEnabled = checked
                    font: Tokens.label
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: qsTr("Blur lab")
                    font: Tokens.label
                    onClicked: {
                        root.close();
                        root.blurRequested();
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                IconButton {
                    iconName: "settings"
                    text: qsTr("Settings preview")
                    onClicked: Shell.launch("settings")
                }
                IconButton {
                    iconName: "power"
                    text: qsTr("Session action preview")
                    onClicked: Shell.system.requestSessionAction("shutdown")
                }
            }
        }
    }
}
