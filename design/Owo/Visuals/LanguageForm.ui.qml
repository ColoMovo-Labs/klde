// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    width: 600
    property alias title: languageTitle.text
    property alias chineseButton: chineseButton
    property alias englishButton: englishButton
    property alias accessibilityButton: accessibilityButton
    property alias continueButton: continueButton
    property string selectedLocale: "zh_CN"
    spacing: Tokens.space16
    Glyph {
        Layout.alignment: Qt.AlignHCenter
        width: 64
        height: 64
    }
    Text {
        id: languageTitle
        objectName: "welcomeLanguageTitle"
        Layout.alignment: Qt.AlignHCenter
        text: "选择语言 / Choose language"
        font: Tokens.headline
        color: Tokens.textPrimary
    }
    AnimatedAction {
        id: chineseButton
        Layout.fillWidth: true
        text: "简体中文"
        checkable: true
        checked: root.selectedLocale === "zh_CN"
        emphasized: checked
        font: Tokens.body
    }
    AnimatedAction {
        id: englishButton
        Layout.fillWidth: true
        text: "English"
        checkable: true
        checked: root.selectedLocale === "en"
        emphasized: checked
        font: Tokens.body
    }
    RowLayout {
        Layout.fillWidth: true
        SmallButton {
            id: accessibilityButton
            iconName: "info"
            text: "辅助功能 / Accessibility"
        }
        Item {
            Layout.fillWidth: true
        }
        AnimatedAction {
            id: continueButton
            text: root.selectedLocale === "zh_CN" ? "继续" : "Continue"
            emphasized: true
        }
    }
}
