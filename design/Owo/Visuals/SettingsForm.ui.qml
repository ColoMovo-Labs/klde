// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 552
    height: column.implicitHeight
    implicitHeight: column.implicitHeight
    property alias themeChoice: themeChoice
    property alias wallpaperChoice: wallpaperChoice
    property alias motionChoice: motionChoice
    property alias densityChoice: densityChoice
    property alias transparencySwitch: transparencySwitch
    property alias shadowsSwitch: shadowsSwitch
    property alias languageButton: languageButton
    property alias effectsButton: effectsButton
    property alias themeText: themeLabel.text
    property alias wallpaperText: wallpaperLabel.text
    property alias motionText: motionLabel.text
    property alias densityText: densityLabel.text
    property alias transparencyText: transparencySwitch.text
    property alias shadowsText: shadowsSwitch.text
    ColumnLayout {
        id: column
        width: parent.width
        spacing: Tokens.space16
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.space12
            columnSpacing: Tokens.space24
            Text {
                id: themeLabel
                text: "主题 / Theme"
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ComboBox {
                id: themeChoice
                Layout.fillWidth: true
                model: ["浅色", "深色", "跟随系统"]
                Accessible.name: themeLabel.text
            }
            Text {
                id: wallpaperLabel
                text: "壁纸 / Wallpaper"
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ComboBox {
                id: wallpaperChoice
                Layout.fillWidth: true
                model: ["云霜", "抽象", "静谧", "Kemono"]
                Accessible.name: wallpaperLabel.text
            }
            Text {
                id: motionLabel
                text: "动效 / Motion"
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ComboBox {
                id: motionChoice
                Layout.fillWidth: true
                model: ["轻缓", "标准", "生动"]
                Accessible.name: motionLabel.text
            }
            Text {
                id: densityLabel
                text: "密度 / Density"
                font: Tokens.label
                color: Tokens.textPrimary
            }
            ComboBox {
                id: densityChoice
                Layout.fillWidth: true
                model: ["宽松", "均衡", "紧凑"]
                currentIndex: 1
                Accessible.name: densityLabel.text
            }
        }
        Switch {
            id: transparencySwitch
            text: "透明效果 / Transparency"
            checked: true
            font: Tokens.label
        }
        Switch {
            id: shadowsSwitch
            text: "阴影 / Shadows"
            checked: true
            font: Tokens.label
        }
        RowLayout {
            Layout.fillWidth: true
            Button {
                id: languageButton
                text: "语言与输入 / Language & input"
                Layout.fillWidth: true
            }
            Button {
                id: effectsButton
                text: "高级效果 / Advanced effects"
                Layout.fillWidth: true
            }
        }
    }
}
