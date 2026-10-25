// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals

// Only design-time interactions. The production Shell adapters never import this.
Item {
    id: controller
    required property var scene
    signal sceneRequested(string name)
    property var launcher: scene ? scene["launcher"] || null : null
    property var dock: scene ? scene["dock"] || null : null
    property var controls: scene ? scene["controls"] || null : null
    property var language: scene ? scene["language"] || null : null
    property var welcome: scene ? scene["welcome"] || null : null
    property var settings: scene ? scene["settings"] || null : null
    property string notice: ""
    function activateApp(appId: string, index: int): void {
        notice = "Design Preview · " + appId;
        noticeTimer.restart();
    }
    onLauncherChanged: if (launcher)
        launcher.actionTarget = controller
    onDockChanged: if (dock)
        dock.actionTarget = controller
    Timer {
        id: noticeTimer
        interval: 1800
        onTriggered: controller.notice = ""
    }
    Connections {
        target: controller.launcher ? controller.launcher.gridButton : null
        function onClicked(): void {
            controller.launcher.gridMode = true;
        }
    }
    Connections {
        target: controller.launcher ? controller.launcher.listButton : null
        function onClicked(): void {
            controller.launcher.gridMode = false;
        }
    }
    Connections {
        target: controller.launcher ? controller.launcher.closeButton : null
        function onClicked(): void {
            controller.sceneRequested("Desktop");
        }
    }
    Connections {
        target: controller.launcher ? controller.launcher.searchField : null
        function onTextEdited(): void {
            if (controller.scene["applications"])
                controller.scene.applications.filter(controller.launcher.searchField.text);
        }
    }
    Connections {
        target: controller.dock ? controller.dock.launcherButton : null
        function onClicked(): void {
            controller.sceneRequested("Desktop");
        }
    }
    Connections {
        target: controller.controls ? controller.controls.wifiButton : null
        function onClicked(): void {
            controller.controls.wifiOn = !controller.controls.wifiOn;
        }
    }
    Connections {
        target: controller.controls ? controller.controls.bluetoothButton : null
        function onClicked(): void {
            controller.controls.bluetoothOn = !controller.controls.bluetoothOn;
        }
    }
    Connections {
        target: controller.controls ? controller.controls.nightButton : null
        function onClicked(): void {
            controller.controls.nightOn = !controller.controls.nightOn;
        }
    }
    Connections {
        target: controller.controls ? controller.controls.motionButton : null
        function onClicked(): void {
            controller.controls.quietOn = !controller.controls.quietOn;
        }
    }
    Connections {
        target: controller.controls ? controller.controls.dndButton : null
        function onClicked(): void {
            controller.controls.dndOn = !controller.controls.dndOn;
        }
    }
    Connections {
        target: controller.controls ? controller.controls.microphoneButton : null
        function onClicked(): void {
            controller.controls.microphoneOn = !controller.controls.microphoneOn;
        }
    }
    Connections {
        target: controller.controls ? controller.controls.closeButton : null
        function onClicked(): void {
            controller.sceneRequested("Desktop");
        }
    }
    Connections {
        target: controller.controls ? controller.controls.settingsButton : null
        function onClicked(): void {
            controller.sceneRequested("Settings");
        }
    }
    Connections {
        target: controller.language ? controller.language.chineseButton : null
        function onClicked(): void {
            Tokens.locale = "zh_CN";
            controller.language.selectedLocale = "zh_CN";
        }
    }
    Connections {
        target: controller.language ? controller.language.englishButton : null
        function onClicked(): void {
            Tokens.locale = "en";
            controller.language.selectedLocale = "en";
        }
    }
    Connections {
        target: controller.language ? controller.language.continueButton : null
        function onClicked(): void {
            controller.sceneRequested("Welcome");
        }
    }
    Connections {
        target: controller.welcome ? controller.welcome.startButton : null
        function onClicked(): void {
            controller.sceneRequested("Settings");
        }
    }
    Connections {
        target: controller.settings ? controller.settings.themeChoice : null
        function onActivated(index: int): void {
            Tokens.darkMode = index === 1;
        }
    }
    Connections {
        target: controller.settings ? controller.settings.wallpaperChoice : null
        function onActivated(index: int): void {
            Tokens.wallpaperChoice = ["snow", "abstract", "quiet", "kemono"][index];
        }
    }
    Connections {
        target: controller.settings ? controller.settings.motionChoice : null
        function onActivated(index: int): void {
            Tokens.reducedMotion = index === 0;
        }
    }
    Connections {
        target: controller.settings ? controller.settings.densityChoice : null
        function onActivated(index: int): void {
            Tokens.densityMode = index;
        }
    }
}
