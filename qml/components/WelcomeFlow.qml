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
    property Item backdropSource: null
    signal finished

    readonly property int pageCount: 10
    readonly property var pageIds: ["welcome", "language", "input", "appearance", "window", "privacy", "accounts", "updates", "preparation", "ready"]
    readonly property string pageId: pageIds[Math.max(0, Math.min(pageIndex, pageCount - 1))]
    readonly property string pageTitle: {
        switch (pageId) {
        case "welcome":
            return I18n.t("welcome.title");
        case "language":
            return I18n.t("welcome.language.title");
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
    function back(): void {
        if (pageIndex > 0)
            pageIndex -= 1;
    }
    function skipToDesktop(): void {
        root.finished();
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
                text: "Welcome"
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

                    Item {
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.space24
                            spacing: Tokens.space32
                            ColumnLayout {
                                Layout.preferredWidth: 340
                                spacing: Tokens.space12
                                Label {
                                    text: "Coding for Furry & Kemono."
                                    color: Tokens.primary
                                    font: Tokens.title
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
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
                                    }
                                }
                            }
                            Item {
                                Layout.preferredWidth: 260
                                Layout.preferredHeight: 360
                                Image {
                                    anchors.fill: parent
                                    source: "qrc:/assets/welcome/klde-guide-wave.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                            }
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.language.title")
                            choices: ["中文（简体）", "English"]
                            selected: 0
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.input.title")
                            choices: ["English", "Pinyin", "Shuangpin", "Wubi"]
                            selected: 1
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.appearance.title")
                            choices: [I18n.t("common.light"), I18n.t("common.dark"), I18n.t("common.auto")]
                            selected: 0
                        }
                    }
                    Item {
                        WelcomeChoicePage {
                            title: I18n.t("welcome.window.title")
                            choices: [I18n.t("shell.workspace.floating"), I18n.t("shell.workspace.tiled"), I18n.t("lab.workspace.scrolling"), I18n.t("shell.workspace.mixed")]
                            selected: 3
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
                checked: index === selected
                onClicked: selected = index
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
