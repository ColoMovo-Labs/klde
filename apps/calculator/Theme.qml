// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick

QtObject {
    readonly property var colors: MonetPalette.paletteFor(Calculator.wallpaper, Calculator.dark)
    readonly property int space: 8
    readonly property int margin: 24
    readonly property int keyRadius: 16
    readonly property int motion: 140
    readonly property int textSize: 16
}
