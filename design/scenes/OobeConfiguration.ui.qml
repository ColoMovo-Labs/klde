// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Owo.Visuals

Item {
    width: 960
    height: 720
    SurfaceForm {
        anchors.fill: parent
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.space32
        spacing: Tokens.space24
        PanelHeaderForm {
            Layout.fillWidth: true
            title: "首次设置 · 配置页面"
            subtitle: "仅视觉与模拟选项 / Design only"
        }
        ComboBox {
            id: step
            Layout.fillWidth: true
            model: ["地区与时区", "键盘与输入法", "外观", "窗口布局", "隐私", "账户", "更新"]
        }
        ChoicePageForm {
            Layout.fillWidth: true
            selected: 0
            choices: step.currentIndex === 0 ? ["跟随系统", "中国", "美国"] : step.currentIndex === 1 ? ["English", "Pinyin", "Shuangpin", "Wubi"] : step.currentIndex === 2 ? ["浅色", "深色", "自动"] : step.currentIndex === 3 ? ["浮动", "经典平铺", "滚动平铺", "混合"] : step.currentIndex === 4 ? ["天气", "位置", "在线账户", "更新"] : step.currentIndex === 5 ? ["保持离线", "稍后添加账户"] : ["手动检查", "稍后设置"]
        }
        Item {
            Layout.fillHeight: true
        }
    }
    states: [
        State {
            name: "light"
            PropertyChanges {
                target: Tokens
                darkMode: false
            }
        },
        State {
            name: "dark"
            PropertyChanges {
                target: Tokens
                darkMode: true
            }
        }
    ]
}
