// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtTest
import KLDE.Shell
import KLDE.Backends

Item {
    id: testRoot
    width: 1280
    height: 800
    Component {
        id: centerComponent
        SettingsCenter {}
    }
    TestCase {
        name: "SettingsCenter"
        when: windowShown
        property var center
        function init(): void {
            Tokens.reducedMotion = true;
            Shell.mockScenarios.apply("laptop-balanced");
            Shell.language.setLocale("en");
            center = createTemporaryObject(centerComponent, testRoot, {
                parent: testRoot
            });
            verify(center !== null);
            center.open();
            tryCompare(center, "opened", true);
        }
        function cleanup(): void {
            center.close();
            Shell.settings.reset("appearance.accent");
            Tokens.reducedMotion = false;
        }
        function test_everyPageLoadsAndHasAHeadline(): void {
            const loader = findChild(center, "settingsPageLoader");
            const headline = findChild(center, "settingsHeadline");
            verify(loader !== null && headline !== null);
            compare(center.pages.length, 13);
            for (const entry of center.pages) {
                center.openPage(entry.id);
                compare(center.page, entry.id);
                tryVerify(() => loader.status === Loader.Ready && loader.item !== null);
                compare(headline.text, I18n.t("settings.page." + entry.id));
                verify(loader.item.implicitHeight > 0);
            }
        }
        function test_keyboardNavigatesCategoriesAndCloses(): void {
            const navigation = findChild(center, "settingsNavigation");
            verify(navigation !== null);
            tryVerify(() => navigation.activeFocus);
            compare(center.page, "appearance");
            keyClick(Qt.Key_Down);
            compare(center.page, "desktop");
            keyClick(Qt.Key_Down);
            compare(center.page, "ribbon");
            keyClick(Qt.Key_Up);
            compare(center.page, "desktop");
            keyClick(Qt.Key_Tab, Qt.ControlModifier);
            compare(center.page, "ribbon");
            keyClick(Qt.Key_Right);
            verify(!navigation.activeFocus);
            keyClick(Qt.Key_Escape);
            tryCompare(center, "opened", false);
        }
        function test_enterMovesFocusIntoThePage(): void {
            center.openPage("network");
            const navigation = findChild(center, "settingsNavigation");
            navigation.forceActiveFocus();
            keyClick(Qt.Key_Return);
            const wifi = findChild(center, "settingsWifi");
            verify(wifi !== null);
            tryVerify(() => wifi.activeFocus);
        }
        function test_displaysListEveryScreen(): void {
            verify(Shell.screens.count >= 1);
            center.openPage("displays");
            const first = Shell.screens.get(0);
            tryCompare(findChild(center, "settingsScreens"), "count", Shell.screens.count);
            verify(first.geometry.width > 0);
            verify(first.pixelRatio > 0);
            verify(findChild(center, "settingsDockAllScreens") !== null);
        }
        function test_aboutSummarizesSimulatedSources(): void {
            center.openPage("about");
            tryVerify(() => findChild(center, "settingsSources") !== null);
            compare(findChild(center, "settingsSources").count, 16);
            const loader = findChild(center, "settingsPageLoader");
            const network = loader.item.sources.find(source => source.id === "network");
            compare(network.live, Shell.state.livePaths.indexOf("network.enabled") >= 0);
            verify(!loader.item.sources.find(source => source.id === "android").live);
        }
        function test_accentIsStoredInSettings(): void {
            Shell.settings.setValue("appearance.accent", "lilac");
            compare(Shell.settings.values["appearance.accent"], "lilac");
            verify(!Shell.settings.persistent);
        }
    }
}
