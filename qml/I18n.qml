// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import KLDE.Backends

QtObject {
    readonly property string locale: Shell.language.locale
    readonly property string voice: Shell.language.voice
    function t(id: string): string {
        return Shell.language.text(id, Shell.language.revision).replace(/\{brand\}/g, Branding.displayName);
    }
    function s(source: string): string {
        return Shell.language.sourceText(source, Shell.language.revision).replace(/\{brand\}/g, Branding.displayName);
    }
    function number(value: real, precision: int): string {
        return value.toLocaleString(Qt.locale(locale), "f", precision);
    }
    function date(value: string, compact: bool): string {
        return new Date(value).toLocaleDateString(Qt.locale(locale), compact ? locale === "zh_CN" ? "M月d日 ddd" : "MMM d, ddd" : Locale.LongFormat);
    }
    function clock(): string {
        return Shell.language.previewClock(Shell.language.revision);
    }
}
