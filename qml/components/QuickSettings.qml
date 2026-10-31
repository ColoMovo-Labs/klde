// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "quickSettings"
    signal blurRequested
    signal settingsRequested
    signal viewRequested(string view)
    // Kept for CLI/Visual Lab compatibility. All everyday controls are always shown.
    property bool expanded: false
    property int microphoneRestoreLevel: 82
    readonly property var snapshot: Shell.state.snapshot
    width: Math.min(Tokens.panelWidth + Tokens.space16, parent ? parent.width - Tokens.space32 : Tokens.panelWidth)
    height: Math.min(form.implicitHeight + padding * 2, parent ? parent.height - y - Tokens.space24 : Tokens.previewHeight)
    contentItem: ScrollView {
        id: scroller
        contentWidth: availableWidth
        clip: true
        QuickSettingsForm {
            id: form
            width: scroller.availableWidth
            height: implicitHeight
            wifiOn: root.snapshot.network.enabled
            bluetoothOn: root.snapshot.bluetooth.enabled
            bluetoothAvailable: root.snapshot.capabilities.bluetooth
            brightnessAvailable: root.snapshot.capabilities.brightness
            microphoneAvailable: root.snapshot.capabilities.microphone
            microphoneOn: root.snapshot.audio.microphone > 0
            nightOn: Shell.system.nightMode
            quietOn: Shell.scenes.current.visual.motion === 0
            dndOn: root.snapshot.notifications.dnd
            wifiDetail: root.snapshot.network.connected ? root.snapshot.network.ssid : I18n.t("lab.network.offline")
            provenance: I18n.t("shell.quick.provenance")
            wifiLabel: I18n.t("shell.network.wifi")
            bluetoothLabel: I18n.t("shell.network.bluetooth")
            dndLabel: I18n.t("lab.dnd")
            nightLabel: I18n.t("shell.effects.night")
            motionLabel: I18n.t("shell.effects.quiet")
            microphoneLabel: I18n.t("lab.module.microphone")
            brightnessLabel: I18n.t("shell.effects.brightness")
            volumeLabel: I18n.t("shell.effects.volume")
            settingsLabel: I18n.t("shell.settings.open")
            moreLabel: I18n.t("settings.open")
            powerLabel: Shell.session.managed ? I18n.t("session.logout.confirm") : I18n.t("destructive.session.preview")
            brightnessSlider.value: Shell.system.brightness
            volumeSlider.value: Shell.system.volume
            microphoneSlider.value: root.snapshot.audio.microphone
            profileLabels: [I18n.t("shell.scene.performance"), I18n.t("shell.scene.balanced"), I18n.t("shell.scene.saver")]
            profileChoice.currentIndex: Shell.scenes.activeId === "performance" ? 0 : Shell.scenes.activeId === "balanced" ? 1 : 2
        }
    }
    Connections {
        target: form.closeButton
        function onClicked(): void {
            root.close();
        }
    }
    Connections {
        target: form.settingsButton
        function onClicked(): void {
            root.close();
            root.settingsRequested();
        }
    }
    Connections {
        target: form.powerButton
        function onClicked(): void {
            if (Shell.session.managed)
                root.viewRequested("session");
            else
                Shell.system.requestSessionAction("shutdown");
        }
    }
    Connections {
        target: form.wifiButton
        function onClicked(): void {
            Shell.system.wifi = !Shell.system.wifi;
        }
    }
    Connections {
        target: form.bluetoothButton
        function onClicked(): void {
            Shell.system.bluetooth = !Shell.system.bluetooth;
        }
    }
    Connections {
        target: form.nightButton
        function onClicked(): void {
            Shell.system.nightMode = !Shell.system.nightMode;
        }
    }
    Connections {
        target: form.motionButton
        function onClicked(): void {
            Shell.scenes.customize("motion", Tokens.reducedMotion ? 1 : 0);
        }
    }
    Connections {
        target: form.dndButton
        function onClicked(): void {
            Shell.state.requestValue("notifications.dnd", !root.snapshot.notifications.dnd);
        }
    }
    Connections {
        target: form.microphoneButton
        function onClicked(): void {
            if (root.snapshot.audio.microphone > 0) {
                root.microphoneRestoreLevel = root.snapshot.audio.microphone;
                Shell.state.requestValue("audio.microphone", 0);
            } else {
                Shell.state.requestValue("audio.microphone", root.microphoneRestoreLevel);
            }
        }
    }
    Connections {
        target: form.brightnessSlider
        function onMoved(): void {
            Shell.system.brightness = Math.round(form.brightnessSlider.value);
        }
    }
    Connections {
        target: form.volumeSlider
        function onMoved(): void {
            Shell.system.volume = Math.round(form.volumeSlider.value);
        }
    }
    Connections {
        target: form.microphoneSlider
        function onMoved(): void {
            Shell.state.requestValue("audio.microphone", Math.round(form.microphoneSlider.value));
        }
    }
    Connections {
        target: form.profileChoice
        function onActivated(index: int): void {
            Shell.scenes.select(["performance", "balanced", "power-saver"][index]);
        }
    }
    Connections {
        target: form.moreButton
        function onClicked(): void {
            root.close();
            root.settingsRequested();
        }
    }
}
