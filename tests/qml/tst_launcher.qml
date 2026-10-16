// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import KLDE.Shell
import KLDE.Backends

Item {
    id: testRoot
    width: 800
    height: 600
    Component {
        id: launcherComponent
        Launcher {}
    }
    TestCase {
        name: "LauncherInteraction"
        when: windowShown
        property var popup
        function init(): void {
            Tokens.reducedMotion = true;
            Shell.search.query = "";
            popup = createTemporaryObject(launcherComponent, testRoot, {
                "parent": testRoot
            });
            verify(popup !== null);
            popup.open();
            tryCompare(popup, "opened", true);
        }
        function cleanup(): void {
            popup.close();
            Shell.search.query = "";
            Tokens.reducedMotion = false;
        }
        function test_searchFocusTypingAndEnterActivation(): void {
            const search = findChild(popup, "launcherSearch");
            verify(search !== null);
            tryCompare(search, "activeFocus", true);
            keyClick(Qt.Key_T);
            compare(Shell.search.query, "t");
            Shell.search.query = "terminal";
            compare(Shell.search.count, 1);
            keyClick(Qt.Key_Return);
            tryCompare(popup, "opened", false);
            verify(Shell.message.indexOf("Terminal") >= 0);
        }
        function test_escapeClosesTheLauncher(): void {
            keyClick(Qt.Key_Escape);
            tryCompare(popup, "opened", false);
        }
    }
}
