// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import KLDE.Backends

ApplicationWindow {
    id: window
    property string initialView: "desktop"
    property bool initialDark: false
    objectName: "shellWindow"
    width: Tokens.previewWidth
    height: Tokens.previewHeight
    minimumWidth: Tokens.previewMinimumWidth
    minimumHeight: Tokens.previewMinimumHeight
    visible: true
    title: qsTr("KLDE Shell — Preview")
    color: Tokens.background
    font: Tokens.body
    palette.window: Tokens.surface
    palette.windowText: Tokens.textPrimary
    palette.base: Tokens.surfaceElevated
    palette.text: Tokens.textPrimary
    palette.button: Tokens.surfaceContainer
    palette.buttonText: Tokens.textPrimary
    palette.highlight: Tokens.primary
    palette.highlightedText: Tokens.onPrimary

    readonly property bool renderingAllowed: visible && visibility !== Window.Minimized
    onRenderingAllowedChanged: Shell.blur.renderingAllowed = renderingAllowed
    Component.onCompleted: {
        Tokens.darkMode = initialDark;
        if (initialView === "quick-settings")
            quickSettings.open();
        else if (initialView === "launcher")
            launcher.open();
        else if (initialView === "blur")
            blurLab.open();
    }

    Image {
        anchors.fill: parent
        source: "qrc:/assets/wallpapers/first-light.svg"
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle {
        anchors.fill: parent
        color: Tokens.background
        opacity: Tokens.darkMode ? Tokens.darkWallpaperShade : 0
    }
    RowLayout {
        x: Tokens.desktopMargin
        y: Tokens.space24
        spacing: Tokens.space12
        Icon {
            name: "klde"
            width: Tokens.iconL
            height: Tokens.iconL
        }
        ColumnLayout {
            spacing: Tokens.space2
            Label {
                text: "KLDE"
                font: Tokens.title
                color: Tokens.textPrimary
            }
            Label {
                objectName: "statusLabel"
                text: qsTr("PREVIEW · MOCK SERVICES")
                font: Tokens.caption
                color: Tokens.textSecondary
            }
        }
    }
    WorkspaceIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.space24
    }
    Button {
        id: quickButton
        objectName: "quickSettingsButton"
        anchors.right: parent.right
        anchors.rightMargin: Tokens.desktopMargin
        y: Tokens.space24
        text: qsTr("09:41  ·  Controls")
        font: Tokens.label
        Accessible.name: qsTr("Open quick settings, preview clock 09:41")
        onClicked: quickSettings.opened ? quickSettings.close() : quickSettings.open()
    }
    WidgetHost {
        widgetId: "weather"
        x: Tokens.desktopMargin
        y: Tokens.controlHeight + Tokens.space32 * 3
        renderingAllowed: window.renderingAllowed
        sourceComponent: Component {
            WeatherWidget {
                weather: Shell.weather
            }
        }
    }
    ColumnLayout {
        x: Tokens.desktopMargin
        anchors.bottom: dock.top
        anchors.bottomMargin: Tokens.space32
        spacing: Tokens.space8
        Label {
            text: qsTr("A little room\nto make things.")
            font: Tokens.display
            color: Tokens.textPrimary
        }
        Label {
            text: qsTr("Ctrl+Space to explore · F2 for your controls")
            font: Tokens.label
            color: Tokens.textSecondary
        }
    }
    Dock {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.space24
        onLauncherRequested: launcher.open()
        onSettingsRequested: {
            Shell.launch("settings");
            quickSettings.open();
        }
    }
    Launcher {
        id: launcher
        parent: Overlay.overlay
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: {
            if (!quickSettings.opened && !blurLab.opened)
                dock.focusLauncher();
        }
    }
    QuickSettings {
        id: quickSettings
        parent: Overlay.overlay
        x: parent ? parent.width - width - Tokens.desktopMargin : 0
        y: Tokens.controlHeight + Tokens.space24 * 2
        onBlurRequested: blurLab.open()
        onClosed: {
            if (!launcher.opened && !blurLab.opened)
                quickButton.forceActiveFocus();
        }
    }
    BlurLab {
        id: blurLab
        parent: Overlay.overlay
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        onClosed: quickButton.forceActiveFocus()
    }
    Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dock.top
        anchors.bottomMargin: Tokens.space16
        width: Tokens.panelWidth
        height: noticeText.implicitHeight + Tokens.space32
        opacity: Shell.message.length > 0 ? 1 : 0
        visible: opacity > 0
        Label {
            id: noticeText
            anchors.fill: parent
            text: Shell.message + (Shell.osdValue >= 0 ? "  " + Shell.osdValue + "%" : "")
            font: Tokens.label
            color: Tokens.textPrimary
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.motionFast
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: launcher.opened ? launcher.close() : launcher.open()
    }
    Shortcut {
        sequence: "F2"
        onActivated: quickSettings.opened ? quickSettings.close() : quickSettings.open()
    }
    Shortcut {
        sequence: "Ctrl+Alt+B"
        onActivated: blurLab.open()
    }
    Shortcut {
        sequence: "Ctrl+Alt+R"
        onActivated: Tokens.reducedMotion = !Tokens.reducedMotion
    }
}
