// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1100
    height: 640
    property string headline: Tokens.locale === "zh_CN" ? "欢迎使用 owoDE" : "Welcome to owoDE"
    property string intro: Tokens.locale === "zh_CN" ? "一个安静、富有表现力，为想法留出空间的桌面。" : "A calm, expressive desktop with room for your ideas."
    property string startText: Tokens.locale === "zh_CN" ? "开始设置" : "Get started"
    property string accessibilityText: Tokens.locale === "zh_CN" ? "辅助功能" : "Accessibility"
    property real revealProgress: 1
    property alias startButton: startButton
    property alias accessibilityButton: accessibilityButton
    property alias wordmark: wordmark
    Image {
        id: character
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.49
        height: parent.height * 0.82
        source: Assets.root + "welcome/klde-guide-hero-v2.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: Tokens.space24
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.48
        spacing: Tokens.space16
        Text {
            text: root.headline
            color: Tokens.textPrimary
            font: Tokens.display
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 182
            Item {
                width: parent.width * root.revealProgress
                height: parent.height
                clip: true
                Image {
                    id: wordmark
                    width: parent.parent.width
                    height: parent.height
                    source: Assets.root + "welcome/klde-wordmark.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }
        }
        Text {
            text: root.intro
            color: Tokens.textSecondary
            font: Tokens.body
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        RowLayout {
            AnimatedAction {
                id: startButton
                text: root.startText
                font: Tokens.label
                emphasized: true
                palette.buttonText: Tokens.textOnPrimary
                palette.button: Tokens.primary
            }
            AnimatedAction {
                id: accessibilityButton
                text: root.accessibilityText
                font: Tokens.label
                palette.buttonText: Tokens.textPrimary
            }
        }
    }
}
