// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals

// One asset route for app-provider images, ordinary glyphs and the current brand.
Item {
    property alias name: glyph.name
    property alias lightInk: glyph.lightInk
    implicitWidth: Tokens.iconM
    implicitHeight: Tokens.iconM
    Glyph {
        id: glyph
        anchors.fill: parent
    }
}
