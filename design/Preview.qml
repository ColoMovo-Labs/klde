// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals

ApplicationWindow {
    id: root
    width: 1440
    height: 980
    visible: true
    title: "owoDE · v0.0.1 Alpha · YunShuang · Design Preview"
    color: Tokens.background
    property string sceneName: "Desktop"
    property real previewScale: 1
    property int viewportWidth: 1440
    property int viewportHeight: 900
    readonly property var scenes: ["Desktop", "Background", "TopRibbon", "Dock", "Launcher", "QuickSettings", "NotificationCenter", "LockScreen", "Language", "Welcome", "Settings", "WindowOsd"]
    palette.window: Tokens.surface
    palette.text: Tokens.textPrimary
    palette.buttonText: Tokens.textPrimary
    palette.highlight: Tokens.primaryContainer
    palette.highlightedText: Tokens.textPrimary
    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            Label {
                text: "Design Preview · 模拟数据"
                padding: 8
                color: Tokens.textPrimary
            }
            ComboBox {
                model: root.scenes
                currentIndex: root.scenes.indexOf(root.sceneName)
                onActivated: root.sceneName = root.scenes[currentIndex]
            }
            ComboBox {
                model: ["1440 × 900", "1920 × 1080", "1280 × 720", "1024 × 768"]
                onActivated: {
                    const sizes = [[1440, 900], [1920, 1080], [1280, 720], [1024, 768]];
                    root.viewportWidth = sizes[currentIndex][0];
                    root.viewportHeight = sizes[currentIndex][1];
                }
            }
            ComboBox {
                model: ["100%", "125%", "150%", "200%"]
                onActivated: Tokens.textScale = [1, 1.25, 1.5, 2][currentIndex]
            }
            Switch {
                text: "Dark"
                onToggled: Tokens.darkMode = checked
            }
            Item {
                Layout.fillWidth: true
            }
            Label {
                text: "v0.0.1 Alpha · 云霜"
                color: Tokens.textSecondary
                padding: 8
            }
        }
    }
    ScrollView {
        anchors.fill: parent
        contentWidth: Math.max(width, root.viewportWidth * root.previewScale)
        contentHeight: Math.max(height, root.viewportHeight * root.previewScale)
        Item {
            width: root.viewportWidth
            height: root.viewportHeight
            scale: root.previewScale
            transformOrigin: Item.TopLeft
            Loader {
                id: scene
                anchors.fill: parent
                source: "scenes/" + root.sceneName + ".ui.qml"
            }
        }
    }
}
