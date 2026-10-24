// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

ListModel {
    id: root
    property var sourceRows: []
    Component.onCompleted: {
        const rows = [];
        for (let i = 0; i < count; ++i)
            rows.push(JSON.parse(JSON.stringify(get(i))));
        sourceRows = rows;
    }
    function filter(query: string): void {
        clear();
        for (const row of sourceRows)
            if ((row.displayName + row.description + row.appId).toLowerCase().indexOf(query.toLowerCase()) >= 0)
                append(row);
    }

    ListElement {
        appId: "files"
        displayName: "文件管理器"
        description: "常用文件与位置"
        iconName: "folder"
        running: true
        active: false
    }
    ListElement {
        appId: "browser"
        displayName: "浏览器"
        description: "看看更大的世界"
        iconName: "globe"
        running: true
        active: false
    }
    ListElement {
        appId: "terminal"
        displayName: "终端"
        description: "从一行命令开始"
        iconName: "terminal"
        running: true
        active: false
    }
    ListElement {
        appId: "notes"
        displayName: "笔记"
        description: "记住一闪而过的想法"
        iconName: "note"
        running: false
        active: false
    }
    ListElement {
        appId: "music"
        displayName: "音乐"
        description: "留一点自己的节奏"
        iconName: "music"
        running: true
        active: true
    }
    ListElement {
        appId: "settings"
        displayName: "设置"
        description: "你的桌面，你的方式"
        iconName: "settings"
        running: false
        active: false
    }
}
