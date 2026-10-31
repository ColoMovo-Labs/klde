// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Owo.Visuals
import QtTest
import KLDE.Shell
import KLDE.Backends

Item {
    id: testRoot
    width: 1280
    height: 720
    Component {
        id: dockComponent
        AutoHideDock {
            x: (testRoot.width - width) / 2
            y: testRoot.height - height - Tokens.space24
            width: implicitWidth
            height: implicitHeight
            edgeGap: Tokens.space24
            maximumWidth: testRoot.width - Tokens.space32
        }
    }
    TestCase {
        name: "AutoHideDock"
        when: windowShown
        function init(): void {
            Tokens.reducedMotion = true;
        }
        function cleanup(): void {
            Tokens.reducedMotion = false;
        }
        function create(mode: string): var {
            const dock = createTemporaryObject(dockComponent, testRoot, {
                mode: mode
            });
            verify(dock !== null);
            return dock;
        }
        function test_smartWithoutKnownGeometryStaysVisible(): void {
            const dock = create("smart");
            verify(!dock.covered);
            compare(dock.reveal, 1);
            verify(dock.dock.visible);
            compare(findChild(dock, "dockEdgeTrigger").visible, false);
        }
        function test_hiddenLeavesOnlyAThinTrigger(): void {
            const dock = create("hidden");
            tryCompare(dock, "shown", false);
            tryCompare(dock, "reveal", 0);
            verify(!dock.dock.visible);
            const trigger = findChild(dock, "dockEdgeTrigger");
            verify(trigger.visible);
            compare(trigger.height, Tokens.space4);
            // The strip sits on the screen edge, below the resting dock.
            compare(dock.mapToItem(testRoot, 0, trigger.y + trigger.height).y, testRoot.height);
        }
        function test_peekRevealsAndThenHidesAgain(): void {
            const dock = create("hidden");
            tryCompare(dock, "reveal", 0);
            dock.peek();
            compare(dock.shown, true);
            tryCompare(dock, "reveal", 1);
            tryCompare(dock, "shown", false, 4000);
            tryCompare(dock, "reveal", 0);
        }
        function test_pointerOnTheEdgeRevealsTheDock(): void {
            const dock = create("hidden");
            tryCompare(dock, "reveal", 0);
            mouseMove(testRoot, testRoot.width / 2, testRoot.height / 2);
            mouseMove(testRoot, testRoot.width / 2, testRoot.height - 2);
            mouseMove(testRoot, testRoot.width / 2 + 1, testRoot.height - 1);
            tryCompare(dock, "shown", true);
            mouseMove(testRoot, testRoot.width / 2, dock.y + dock.height / 2);
            wait(600);
            compare(dock.shown, true);
            mouseMove(testRoot, 10, 10);
            tryCompare(dock, "shown", false, 3000);
        }
        function test_reserveNeverHides(): void {
            const dock = create("reserve");
            compare(dock.reveal, 1);
            compare(findChild(dock, "dockEdgeTrigger").visible, false);
        }
    }
}
