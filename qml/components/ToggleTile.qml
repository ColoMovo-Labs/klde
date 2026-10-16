// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root
    property string iconName: "wifi"
    property string detail: checked ? qsTr("On") : qsTr("Off")
    property bool selected: false
    signal toggleRequested
    checkable: true
    checked: selected
    implicitHeight: Tokens.controlHeight * 2 + Tokens.space8
    Accessible.name: text + ", " + detail
    onClicked: toggleRequested()
    contentItem: ColumnLayout {
        spacing: Tokens.space4
        Icon {
            name: root.iconName
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: Tokens.iconM
            Layout.preferredHeight: Tokens.iconM
        }
        Text {
            text: root.text
            font: Tokens.label
            color: Tokens.textPrimary
        }
        Text {
            text: root.detail
            font: Tokens.caption
            color: Tokens.textSecondary
        }
    }
    background: Rectangle {
        radius: root.checked ? Tokens.radiusL : Tokens.radiusM
        color: root.checked || root.hovered ? Tokens.primaryContainer : Tokens.surfaceContainer
        border.width: root.visualFocus ? Tokens.space2 : 0
        border.color: Tokens.outline
        Behavior on color {
            ColorAnimation {
                duration: Tokens.motionFast
            }
        }
    }
}
