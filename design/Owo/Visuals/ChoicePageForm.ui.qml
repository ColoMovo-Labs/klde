// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import Owo.Visuals
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    property var choices: []
    property int selected: -1
    property bool toggles: false
    property var actionTarget: null
    spacing: Tokens.space12
    Text {
        text: root.subtitle
        visible: text.length > 0
        color: Tokens.textSecondary
        font: Tokens.body
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Repeater {
        model: root.choices
        delegate: ChoiceAction {
            required property string modelData
            required property int index
            Layout.fillWidth: true
            text: modelData
            checkable: true
            checked: root.toggles ? false : index === root.selected
            emphasized: checked
            actionTarget: root.actionTarget
        }
    }
}
