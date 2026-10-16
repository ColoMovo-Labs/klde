// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import KLDE.Backends

ShellPopup {
    id: root
    objectName: "launcher"
    modal: true
    width: Math.min(Tokens.launcherWidth, parent ? parent.width - Tokens.space32 : Tokens.launcherWidth)
    height: Math.min(Tokens.launcherHeight, parent ? parent.height - Tokens.space32 : Tokens.launcherHeight)
    onOpened: {
        Shell.search.query = "";
        results.currentIndex = 0;
        searchField.forceActiveFocus();
    }
    function activateSelected(): void {
        if (Shell.launch(Shell.search.idAt(results.currentIndex)))
            close();
    }
    contentItem: ColumnLayout {
        spacing: Tokens.space16
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: qsTr("Find your next thing.")
                font: Tokens.title
                color: Tokens.textPrimary
                Layout.fillWidth: true
            }
            IconButton {
                iconName: "close"
                text: qsTr("Close launcher")
                onClicked: root.close()
            }
        }
        TextField {
            id: searchField
            objectName: "launcherSearch"
            Layout.fillWidth: true
            implicitHeight: Tokens.controlHeight + Tokens.space8
            placeholderText: qsTr("Search applications…")
            font: Tokens.body
            text: Shell.search.query
            Accessible.name: qsTr("Search applications")
            selectByMouse: true
            onTextEdited: Shell.search.query = text
            onAccepted: root.activateSelected()
            Keys.onDownPressed: event => {
                results.incrementCurrentIndex();
                event.accepted = true;
            }
            Keys.onUpPressed: event => {
                results.decrementCurrentIndex();
                event.accepted = true;
            }
        }
        ListView {
            id: results
            objectName: "launcherResults"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Shell.search
            currentIndex: 0
            spacing: Tokens.space4
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            delegate: ItemDelegate {
                id: resultRow
                required property int index
                required property string appId
                required property string displayName
                required property string description
                required property string iconName
                width: results.width
                height: Tokens.launcherRow * Tokens.textScale
                highlighted: ListView.isCurrentItem
                Accessible.name: displayName + ", " + description
                onClicked: {
                    Shell.launch(appId);
                    root.close();
                }
                contentItem: RowLayout {
                    spacing: Tokens.space16
                    Icon {
                        name: resultRow.iconName
                        Layout.preferredWidth: Tokens.iconL
                        Layout.preferredHeight: Tokens.iconL
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.space4
                        Label {
                            text: resultRow.displayName
                            font: Tokens.body
                            color: Tokens.textPrimary
                        }
                        Label {
                            text: resultRow.description
                            font: Tokens.caption
                            color: Tokens.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
                background: Rectangle {
                    radius: Tokens.radiusL
                    color: resultRow.highlighted || resultRow.hovered ? Tokens.primaryContainer : "transparent"
                    border.width: resultRow.visualFocus ? Tokens.space2 : 0
                    border.color: Tokens.primary
                }
            }
            Label {
                anchors.centerIn: parent
                visible: results.count === 0
                text: qsTr("No applications found")
                font: Tokens.body
                color: Tokens.textSecondary
            }
        }
        Label {
            text: qsTr("↑ ↓ select     Enter open     Esc close · Preview catalogue")
            font: Tokens.caption
            color: Tokens.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
    Connections {
        target: Shell.search
        function onQueryChanged(): void {
            results.currentIndex = 0;
        }
    }
}
