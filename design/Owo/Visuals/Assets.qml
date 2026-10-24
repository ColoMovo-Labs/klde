// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick

QtObject {
    readonly property url root: Qt.resolvedUrl(".").toString().indexOf("qrc:") === 0 ? "qrc:/assets/" : Qt.resolvedUrl("../../../assets/")
}
