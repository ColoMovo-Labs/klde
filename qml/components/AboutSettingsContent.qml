// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ColumnLayout {
    id: root
    // Which parts of this session read real services and which are simulated.
    readonly property var sources: {
        const live = Shell.state.livePaths;
        const path = name => live.indexOf(name) >= 0;
        return [
            {
                id: "network",
                live: path("network.enabled")
            },
            {
                id: "bluetooth",
                live: path("bluetooth.enabled")
            },
            {
                id: "audio",
                live: path("audio.volume")
            },
            {
                id: "brightness",
                live: path("brightness")
            },
            {
                id: "battery",
                live: path("battery.percent")
            },
            {
                id: "telemetry",
                live: path("cpu.usage")
            },
            {
                id: "power",
                live: path("powerProfile")
            },
            {
                id: "night",
                live: path("nightMode")
            },
            {
                id: "media",
                live: path("media.available")
            },
            {
                id: "weather",
                live: Shell.weatherService.onlineEnabled
            },
            {
                id: "applications",
                live: !Shell.applications.preview
            },
            {
                id: "windows",
                live: Shell.windowManager.capabilities.mock === false && Shell.windowManager.capabilities.available === true
            },
            {
                id: "input",
                live: !Shell.input.simulated && Shell.input.engineAvailable
            },
            {
                id: "android",
                live: false
            },
            {
                id: "wallpaper",
                live: false
            },
            {
                id: "lock",
                live: false
            }
        ];
    }
    spacing: Tokens.space16
    RowLayout {
        spacing: Tokens.space16
        Image {
            source: "qrc:/assets/branding/owode-logo.png"
            sourceSize: Qt.size(Tokens.iconL * 2, Tokens.iconL * 2)
            Layout.preferredWidth: Tokens.iconL * 2
            Layout.preferredHeight: Tokens.iconL * 2
            fillMode: Image.PreserveAspectFit
            Accessible.ignored: true
        }
        ColumnLayout {
            spacing: Tokens.space4
            Label {
                text: Branding.formalName
                font: Tokens.headline
                color: Tokens.textPrimary
            }
            Label {
                text: I18n.t("settings.about.version").arg(Qt.application.version).arg(Branding.codename)
                font: Tokens.body
                color: Tokens.textSecondary
            }
        }
    }
    Label {
        objectName: "settingsAboutSession"
        text: I18n.t("settings.about.session").arg(Shell.session.compositor.length > 0 ? Shell.session.compositor : I18n.t("settings.about.preview")).arg(Shell.displayServer.platform)
        font: Tokens.body
        color: Tokens.textPrimary
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Label {
        objectName: "settingsAboutStore"
        text: Shell.settings.readOnly ? I18n.t("settings.about.store.readonly").arg(Shell.settings.path) : Shell.settings.persistent ? I18n.t("settings.about.store.file").arg(Shell.settings.path).arg(Shell.settings.version) : I18n.t("settings.about.store.memory")
        textFormat: Text.PlainText
        font: Tokens.caption
        color: Tokens.textSecondary
        wrapMode: Text.WrapAnywhere
        Layout.fillWidth: true
    }
    Label {
        text: I18n.t("settings.about.sources")
        font: Tokens.title
        color: Tokens.textPrimary
        Layout.topMargin: Tokens.space8
    }
    Repeater {
        objectName: "settingsSources"
        model: root.sources
        delegate: RowLayout {
            id: sourceRow
            required property var modelData
            objectName: "settingsSource-" + modelData.id
            Layout.fillWidth: true
            spacing: Tokens.space8
            Label {
                text: I18n.t("settings.about.source." + sourceRow.modelData.id)
                font: Tokens.body
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            Label {
                visible: sourceRow.modelData.live
                text: I18n.t("settings.about.live")
                font: Tokens.caption
                color: Tokens.success
            }
            MockBadge {
                mock: !sourceRow.modelData.live
            }
        }
    }
}
