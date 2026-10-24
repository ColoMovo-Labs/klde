// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 400
    height: 600
    minimumWidth: 360
    minimumHeight: 540
    visible: true
    title: Calculator.chinese ? "计算器 · owoDE" : "Calculator · owoDE"
    color: Theme.colors.background
    palette.window: Theme.colors.surface
    palette.windowText: Theme.colors.textPrimary
    palette.text: Theme.colors.textPrimary
    palette.buttonText: Theme.colors.textPrimary
    palette.button: Theme.colors.surfaceContainer
    palette.base: Theme.colors.surface
    palette.highlight: Theme.colors.primary
    palette.highlightedText: Theme.colors.onPrimary
    font.pixelSize: Theme.textSize
    property string previous: ""
    function calculate(): void {
        if (Calculator.evaluate(expression.text)) {
            previous = expression.text + " =";
            expression.text = Calculator.result;
            expression.cursorPosition = expression.length;
        }
    }
    function input(key: string): void {
        if (key === "=") {
            calculate();
        } else if (key === "C") {
            expression.clear();
            previous = "";
            Calculator.clear();
        } else if (key === "⌫") {
            if (expression.selectedText.length)
                expression.remove(expression.selectionStart, expression.selectionEnd);
            else if (expression.cursorPosition > 0)
                expression.remove(expression.cursorPosition - 1, expression.cursorPosition);
        } else {
            expression.insert(expression.cursorPosition, key);
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.margin
        spacing: Theme.space
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: Calculator.chinese ? "计算器" : "Calculator"
                color: Theme.colors.textPrimary
                font.pixelSize: Theme.textSize * 1.5
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            ToolButton {
                text: "ⓘ"
                Accessible.name: Calculator.chinese ? "关于与开源许可" : "About and open-source licenses"
                onClicked: about.open()
            }
        }
        Item {
            Layout.fillHeight: true
        }
        Label {
            Layout.fillWidth: true
            text: root.previous
            color: Theme.colors.textSecondary
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
        }
        TextField {
            id: expression
            objectName: "calculatorExpression"
            Layout.fillWidth: true
            implicitHeight: Theme.margin * 3
            font.pixelSize: Theme.textSize * 2
            color: Theme.colors.textPrimary
            selectionColor: Theme.colors.primaryContainer
            selectedTextColor: Theme.colors.textPrimary
            horizontalAlignment: TextInput.AlignRight
            placeholderText: "0"
            maximumLength: 256
            selectByMouse: true
            focus: true
            Accessible.name: Calculator.chinese ? "算式" : "Expression"
            Keys.onReturnPressed: root.calculate()
            Keys.onEnterPressed: root.calculate()
            Keys.onEscapePressed: root.input("C")
            background: Rectangle {
                radius: Theme.keyRadius
                color: Theme.colors.surface
                border.width: expression.activeFocus ? 2 : 1
                border.color: expression.activeFocus ? Theme.colors.primary : Theme.colors.outline
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.minimumHeight: Theme.margin
            text: Calculator.error
            color: Calculator.dark ? "#ffb4ab" : "#a92d2d"
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.height * 0.53
            columns: 4
            rowSpacing: Theme.space
            columnSpacing: Theme.space
            Repeater {
                model: ["C", "⌫", "%", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+", "(", "0", ".", ")", "="]
                delegate: Button {
                    id: keyButton
                    required property string modelData
                    objectName: "calculatorKey-" + modelData
                    readonly property bool primary: modelData === "="
                    readonly property bool operation: ["C", "⌫", "%", "÷", "×", "−", "+", "(", ")"].indexOf(modelData) >= 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.columnSpan: primary ? 4 : 1
                    text: modelData
                    Accessible.name: modelData === "⌫" ? (Calculator.chinese ? "退格" : "Backspace") : modelData
                    onClicked: {
                        root.input(modelData);
                        if (!visualFocus)
                            expression.forceActiveFocus(Qt.MouseFocusReason);
                    }
                    contentItem: Text {
                        text: keyButton.text
                        color: keyButton.primary ? Theme.colors.onPrimary : keyButton.operation ? Theme.colors.primary : Theme.colors.textPrimary
                        font.pixelSize: Theme.textSize * 1.25
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: keyButton.primary ? Theme.colors.primary : keyButton.down || keyButton.hovered ? Theme.colors.primaryContainer : keyButton.operation ? Theme.colors.surfaceContainer : Theme.colors.surface
                        radius: keyButton.down ? Theme.space : Theme.keyRadius
                        border.width: keyButton.visualFocus ? 2 : 0
                        border.color: Theme.colors.textPrimary
                        Behavior on radius {
                            NumberAnimation {
                                duration: Theme.motion
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.motion
                            }
                        }
                    }
                }
            }
        }
    }
    Popup {
        id: about
        anchors.centerIn: parent
        width: root.width - Theme.margin * 2
        padding: Theme.margin
        modal: true
        focus: true
        contentItem: ColumnLayout {
            Accessible.role: Accessible.Dialog
            Accessible.name: Calculator.chinese ? "关于计算器" : "About Calculator"
            spacing: Theme.space * 2
            Label {
                text: Calculator.chinese ? "关于计算器" : "About Calculator"
                color: Theme.colors.textPrimary
                font.bold: true
            }
            Label {
                Layout.fillWidth: true
                text: (Calculator.chinese ? "owoDE 主题化的 Lingmo Calculator 引擎移植。\n\n" : "An owoDE-themed port of the Lingmo Calculator engine.\n\n") + "LingmoOS / CuteOS · revenmartin\nSpeedCrunch · Ariya Hidayat\nGNU bc · Free Software Foundation / Philip A. Nelson\n\nGPL-3.0-or-later\n/usr/share/doc/owode-calculator/source"
                wrapMode: Text.WordWrap
                color: Theme.colors.textPrimary
            }
            Button {
                text: Calculator.chinese ? "关闭" : "Close"
                onClicked: about.close()
                Layout.alignment: Qt.AlignRight
            }
        }
        background: Rectangle {
            radius: Theme.keyRadius
            color: Theme.colors.surfaceElevated
            border.color: Theme.colors.outline
        }
    }
}
