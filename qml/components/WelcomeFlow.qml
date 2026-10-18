// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "welcomeFlow"
    property int pageIndex: 0
    property bool offline: false
    property bool partialFailure: false
    property bool reducedMotionPreview: Tokens.reducedMotion
    property bool accessibilityPanelVisible: false
    property int privacyMask: 0
    property string regionChoice: "system"
    property string timezoneChoice: "system"
    property Item backdropSource: null
    signal finished

    readonly property int pageCount: 11
    readonly property var pageIds: ["language", "welcome", "region", "input", "appearance", "window", "privacy", "accounts", "updates", "preparation", "ready"]
    readonly property string pageId: pageIds[Math.max(0, Math.min(pageIndex, pageCount - 1))]
    readonly property string pageTitle: {
        switch (pageId) {
        case "language":
            return "KLDE · 选择语言 / Choose language";
        case "welcome":
            return I18n.t("welcome.title");
        case "region":
            return I18n.t("welcome.region.title");
        case "input":
            return I18n.t("welcome.input.title");
        case "appearance":
            return I18n.t("welcome.appearance.title");
        case "window":
            return I18n.t("welcome.window.title");
        case "privacy":
            return I18n.t("welcome.privacy.title");
        case "accounts":
            return I18n.t("welcome.accounts.title");
        case "updates":
            return I18n.t("welcome.updates.title");
        case "preparation":
            return I18n.t("welcome.preparation.title");
        default:
            return I18n.t("welcome.ready.title");
        }
    }

    function next(): void {
        if (pageIndex < pageCount - 1)
            pageIndex += 1;
    }
    function applyChoice(step: string, choiceIndex: int): void {
        if (step === "input")
            Shell.state.requestValue("input.currentId", choiceIndex === 0 ? "keyboard-us" : "pinyin");
        else if (step === "appearance")
            Shell.scenes.customize("theme", choiceIndex === 0 ? "light" : choiceIndex === 1 ? "dark" : "auto");
        else if (step === "window") {
            const layouts = Shell.state.snapshot.workspaces.layouts.slice();
            layouts[Shell.state.snapshot.workspaces.active - 1] = choiceIndex === 0 ? 0 : choiceIndex === 1 ? 1 : choiceIndex === 2 ? 3 : 2;
            Shell.state.requestValue("workspaces.layouts", layouts);
        } else if (step === "region") {
            regionChoice = choiceIndex === 0 ? "system" : choiceIndex === 1 ? "cn" : "us";
            timezoneChoice = regionChoice === "cn" ? "Asia/Shanghai" : regionChoice === "us" ? "America/Los_Angeles" : "system";
        }
    }
    function back(): void {
        if (pageIndex > 0)
            pageIndex -= 1;
    }
    function skipToDesktop(): void {
        root.finished();
    }

    onPageIndexChanged: {
        if (pageId === "welcome" && welcomeWordmark) {
            welcomeWordmark.opacity = root.reducedMotionPreview ? 1 : 0;
            if (!root.reducedMotionPreview)
                Qt.callLater(() => welcomeWordmark.opacity = 1);
        }
        if (!pageStack || root.reducedMotionPreview)
            return;
        pageStack.opacity = 0;
        pageMotion.restart();
    }

    SequentialAnimation {
        id: pageMotion
        NumberAnimation {
            target: pageStack
            property: "opacity"
            to: 1
            duration: Tokens.motionNormal
            easing.type: Tokens.emphasizedDecelerate
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Tokens.background.r, Tokens.background.g, Tokens.background.b, 0.68)
    }

    Item {
        anchors.fill: parent
        anchors.margins: Tokens.space32

        ColumnLayout {
            id: rail
            x: 0
            y: 0
            width: 216
            height: parent.height
            spacing: Tokens.space16
            Label {
                text: Branding.displayName
                color: Tokens.textPrimary
                font: Tokens.headline
            }
            Label {
                text: I18n.t("welcome.sidebar")
                color: Tokens.textSecondary
                font: Tokens.body
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Tokens.outline
            }
            Repeater {
                model: root.pageIds
                delegate: RowLayout {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: Tokens.space8
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: index === root.pageIndex ? Tokens.primary : Tokens.outline
                    }
                    Label {
                        text: I18n.t("welcome.step." + modelData)
                        color: index === root.pageIndex ? Tokens.textPrimary : Tokens.textSecondary
                        font: index === root.pageIndex ? Tokens.label : Tokens.caption
                        Layout.fillWidth: true
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            }
            ActionButton {
                text: I18n.t("welcome.skip")
                onClicked: root.skipToDesktop()
            }
        }

        Surface {
            id: welcomeSurface
            x: rail.x + rail.width + Tokens.space32
            y: 0
            width: parent.width - x
            height: parent.height
            padding: Tokens.space32
            cornerRadius: Tokens.radiusXL
            backdropSource: root.backdropSource

            ColumnLayout {
                anchors.fill: parent
                spacing: Tokens.space24
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: root.pageTitle
                        color: Tokens.textPrimary
                        font: Tokens.headline
                        Layout.fillWidth: true
                    }
                    Label {
                        text: (root.pageIndex + 1) + " / " + root.pageCount
                        color: Tokens.textSecondary
                        font: Tokens.caption
                    }
                }

                StackLayout {
                    id: pageStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.pageIndex
                    opacity: 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.reducedMotionPreview ? 0 : Tokens.motionNormal
                            easing.type: Tokens.emphasizedDecelerate
                        }
                    }

                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.min(640, parent.width - Tokens.space48)
                            spacing: Tokens.space16
                            Icon {
                                name: "klde"
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                            }
                            Label {
                                text: I18n.t("welcome.language.bootstrap")
                                color: Tokens.textPrimary
                                font: Tokens.headline
                            }
                            Label {
                                text: I18n.t("welcome.language.bootstrap.subtitle")
                                color: Tokens.textSecondary
                                font: Tokens.body
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.space12
                                ActionButton {
                                    objectName: "welcomeChinese"
                                    text: "简体中文"
                                    emphasized: Shell.language.locale === "zh_CN"
                                    onClicked: {
                                        Shell.language.setLocale("zh_CN");
                                        root.next();
                                    }
                                }
                                ActionButton {
                                    objectName: "welcomeEnglish"
                                    text: "English"
                                    emphasized: Shell.language.locale === "en"
                                    onClicked: {
                                        Shell.language.setLocale("en");
                                        root.next();
                                    }
                                }
                                ActionButton {
                                    text: I18n.t("welcome.accessibility")
                                    onClicked: root.accessibilityPanelVisible = !root.accessibilityPanelVisible
                                }
                            }
                            Label {
                                visible: root.accessibilityPanelVisible
                                text: I18n.t("welcome.accessibility.detail")
                                color: Tokens.textSecondary
                                font: Tokens.caption
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Item {
                        Item {
                            anchors.fill: parent
                            Image {
                                id: welcomeWordmark
                                anchors.left: parent.left
                                anchors.leftMargin: Tokens.space24
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(520, parent.width * 0.57)
                                height: width * 0.25
                                source: "qrc:/assets/welcome/klde-wordmark.svg"
                                fillMode: Image.PreserveAspectFit
                                opacity: root.reducedMotionPreview ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Tokens.motionNormal
                                    }
                                }
                            }
                            Item {
                                id: waveClip
                                anchors.right: parent.right
                                anchors.rightMargin: Tokens.space24
                                anchors.verticalCenter: parent.verticalCenter
                                width: 310
                                height: 420
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: "qrc:/assets/welcome/klde-guide-wave.png"
                                    sourceClipRect: Qt.rect(0, 0, 1024, 860)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                            }
                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.leftMargin: Tokens.space24
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(500, parent.width * 0.54)
                                spacing: Tokens.space12
                                Label {
                                    text: I18n.t("welcome.title")
                                    color: Tokens.textPrimary
                                    font: Tokens.headline
                                }
                                Label {
                                    text: I18n.t("welcome.intro")
                                    color: Tokens.textSecondary
                                    font: Tokens.body
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: I18n.t("welcome.placeholder")
                                    color: Tokens.textDisabled
                                    font: Tokens.caption
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                RowLayout {
                                    ActionButton {
                                        text: I18n.t("welcome.get-started")
                                        emphasized: true
                                        onClicked: root.next()
                                    }
                                    ActionButton {
                                        text: I18n.t("welcome.accessibility")
                                        onClicked: root.accessibilityPanelVisible = !root.accessibilityPanelVisible
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.region.title")
                            choices: [I18n.t("welcome.region.system"), I18n.t("welcome.region.china"), I18n.t("welcome.region.us")]
                            selected: 0
                            onChoiceActivated: choiceIndex => root.applyChoice("region", choiceIndex)
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.input.title")
                            choices: ["English", "Pinyin", "Shuangpin", "Wubi"]
                            selected: 1
                            onChoiceActivated: choiceIndex => root.applyChoice("input", choiceIndex)
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.appearance.title")
                            choices: [I18n.t("common.light"), I18n.t("common.dark"), I18n.t("common.auto")]
                            selected: 0
                            onChoiceActivated: choiceIndex => root.applyChoice("appearance", choiceIndex)
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.window.title")
                            choices: [I18n.t("shell.workspace.floating"), I18n.t("shell.workspace.tiled"), I18n.t("lab.workspace.scrolling"), I18n.t("shell.workspace.mixed")]
                            selected: 3
                            onChoiceActivated: choiceIndex => root.applyChoice("window", choiceIndex)
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.privacy.title")
                            choices: [I18n.t("welcome.weather"), I18n.t("welcome.location"), I18n.t("welcome.accounts"), I18n.t("welcome.updates")]
                            selected: -1
                            toggles: true
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.accounts.title")
                            choices: ["Google", I18n.t("welcome.skip")]
                            selected: 1
                            subtitle: I18n.t("welcome.accounts.optional")
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.updates.title")
                            choices: [root.offline ? I18n.t("welcome.updates.offline") : I18n.t("welcome.updates.ready"), I18n.t("welcome.skip")]
                            selected: 1
                            subtitle: I18n.t("welcome.updates.nonblocking")
                        }
                    }
                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.min(620, parent.width - Tokens.space32)
                            spacing: Tokens.space12
                            Label {
                                text: I18n.t("welcome.preparation.subtitle")
                                color: Tokens.textSecondary
                                font: Tokens.body
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Repeater {
                                model: [I18n.t("welcome.task.settings"), I18n.t("welcome.task.wallpaper"), I18n.t("welcome.task.input"), I18n.t("welcome.task.index"), root.offline ? I18n.t("welcome.task.offline") : I18n.t("welcome.task.updates")]
                                delegate: RowLayout {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Icon {
                                        name: index < 3 ? "klde" : index === 3 ? "overview" : "wifi"
                                        Layout.preferredWidth: Tokens.iconS
                                        Layout.preferredHeight: Tokens.iconS
                                    }
                                    Label {
                                        text: modelData
                                        color: Tokens.textPrimary
                                        font: Tokens.label
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: index < 3 ? "DONE" : index === 3 ? "RUNNING" : "SKIPPED"
                                        color: index < 3 ? Tokens.success : Tokens.textSecondary
                                        font: Tokens.caption
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Tokens.space16
                            Label {
                                text: I18n.t("welcome.ready.subtitle")
                                color: Tokens.textSecondary
                                font: Tokens.body
                            }
                            ActionButton {
                                text: I18n.t("welcome.enter-desktop")
                                emphasized: true
                                onClicked: root.skipToDesktop()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    ActionButton {
                        visible: root.pageIndex > 0
                        text: I18n.t("welcome.back")
                        onClicked: root.back()
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    ActionButton {
                        visible: root.pageIndex > 0 && root.pageIndex < root.pageCount - 1
                        text: I18n.t("welcome.continue")
                        emphasized: true
                        onClicked: root.next()
                    }
                }
            }
        }
    }

    component WelcomeChoicePage: ColumnLayout {
        property string title
        property string subtitle: ""
        property var choices: []
        property int selected: -1
        property bool toggles: false
        signal choiceActivated(int choiceIndex)
        anchors.centerIn: parent
        width: Math.min(620, parent.width - Tokens.space32)
        spacing: Tokens.space12
        Label {
            text: subtitle
            visible: text.length > 0
            color: Tokens.textSecondary
            font: Tokens.body
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Repeater {
            model: choices
            delegate: Button {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Tokens.controlHeight
                text: modelData
                checkable: true
                checked: toggles ? false : index === selected
                onClicked: {
                    if (!toggles)
                        selected = index;
                    choiceActivated(index);
                }
                font: Tokens.label
                contentItem: Text {
                    text: parent.text
                    color: Tokens.textPrimary
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: Tokens.space16
                }
                background: Rectangle {
                    radius: Tokens.radiusM
                    color: parent.checked ? Tokens.primaryContainer : Tokens.surfaceContainer
                    border.width: parent.visualFocus ? Tokens.space2 : Tokens.space1
                    border.color: parent.checked ? Tokens.primary : Tokens.outline
                }
            }
        }
    }
}
