// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Owo.Visuals
import KLDE.Shell

Item {
    id: testRoot
    width: 1000
    height: 700
    Component {
        id: overviewComponent
        WindowOverview {
            parent: testRoot
        }
    }
    TestCase {
        name: "WindowOverview"
        when: windowShown
        function test_keyboardOverviewActivates(): void {
            const overview = createTemporaryObject(overviewComponent, testRoot);
            verify(overview !== null);
            overview.open();
            tryCompare(overview, "opened", true);
            compare(overview.visibleWindows.length, 1);
            const grid = findChild(overview, "windowOverviewGrid");
            verify(grid !== null);
            tryCompare(grid, "activeFocus", true);
            keyClick(Qt.Key_Return);
            tryCompare(overview, "opened", false);
        }
        function test_deleteUsesBackendCloseRequest(): void {
            const overview = createTemporaryObject(overviewComponent, testRoot);
            verify(overview !== null);
            compare(overview.visibleWindows.length, 1);
            overview.closeWindow(0);
            compare(overview.visibleWindows.length, 1);
        }
    }
}
