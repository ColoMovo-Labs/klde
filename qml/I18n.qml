// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import KLDE.Backends

QtObject {
    readonly property string locale: Shell.language.locale
    readonly property string voice: Shell.language.voice
    function t(id: string): string {
        return Shell.language.text(id, Shell.language.revision);
    }
    function s(source: string): string {
        return Shell.language.sourceText(source, Shell.language.revision);
    }
    function number(value: real, precision: int): string {
        return value.toLocaleString(Qt.locale(locale), "f", precision);
    }
    function clock(): string {
        return Shell.language.previewClock(Shell.language.revision);
    }
}
