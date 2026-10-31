// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtTest
import KLDE.Shell
import KLDE.Backends

Item {
    id: testRoot
    width: 960
    height: 760
    Component {
        id: settingsComponent
        SettingsCenter {
            page: "language"
        }
    }
    TestCase {
        name: "LanguageInputInteraction"
        when: windowShown
        property var popup
        function init(): void {
            Tokens.reducedMotion = true;
            Shell.language.setLocale("en");
            Shell.language.setVoice("standard");
            popup = createTemporaryObject(settingsComponent, testRoot, {
                "parent": testRoot
            });
            verify(popup !== null);
            popup.open();
            tryCompare(popup, "opened", true);
        }
        function cleanup(): void {
            popup.close();
            Shell.language.setLocale("en");
            Shell.language.setVoice("standard");
            Tokens.reducedMotion = false;
        }
        function selectSecondChoice(control): void {
            verify(control !== null);
            control.forceActiveFocus();
            keyClick(Qt.Key_Space);
            tryCompare(control.popup, "opened", true);
            keyClick(Qt.Key_End);
            keyClick(Qt.Key_Return);
            tryCompare(control.popup, "opened", false);
        }
        function test_keyboardChangesLocaleAndVoiceIndependently(): void {
            selectSecondChoice(findChild(popup, "localeSelector"));
            compare(Shell.language.locale, "zh_CN");
            compare(Shell.language.voice, "standard");
            const standard = I18n.t("shell.quick.title");
            const privacy = I18n.t("privacy.weather.disclosure");
            selectSecondChoice(findChild(popup, "voiceSelector"));
            compare(Shell.language.locale, "zh_CN");
            compare(Shell.language.voice, "cute");
            verify(I18n.t("shell.quick.title") !== standard);
            compare(I18n.t("privacy.weather.disclosure"), privacy);
        }
    }
}
