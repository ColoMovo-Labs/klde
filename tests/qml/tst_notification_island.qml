// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Owo.Visuals
import KLDE.Shell

Item {
    id: testRoot
    width: 1000
    height: 600
    QtObject {
        id: source
        property var popup: ({})
        property bool locked: false
        property bool paused: false
        property int advanced: 0
        function pausePopup(value: bool): void {
            paused = value;
        }
        function advancePopup(): void {
            advanced++;
            popup = ({});
        }
        function dismiss(id: string): void {
            popup = ({});
        }
        function invokeAction(id: string, key: string): void {
            popup = ({});
        }
    }
    Component {
        id: islandComponent
        SystemIsland {
            notificationSource: source
            maximumWidth: testRoot.width
        }
    }
    Component {
        id: ribbonComponent
        StatusRibbon {
            width: testRoot.width
            notificationSource: source
        }
    }
    SignalSpy {
        id: clicked
        signalName: "notificationActivated"
    }
    TestCase {
        name: "NotificationIsland"
        when: windowShown
        function init(): void {
            mouseMove(testRoot, testRoot.width - 10, testRoot.height - 10);
            source.popup = ({});
            source.locked = false;
            source.paused = false;
            source.advanced = 0;
            Tokens.reducedMotion = true;
        }
        function cleanup(): void {
            Tokens.reducedMotion = false;
            clicked.target = null;
        }
        function payload(id: string): var {
            return {
                id: id,
                source: "Fixture",
                title: "Hello",
                body: "A real notification",
                icon: "bell",
                severity: 1,
                actions: []
            };
        }
        function test_expandsAndReturnsToItsRestingSize(): void {
            const island = createTemporaryObject(islandComponent, testRoot);
            verify(island !== null);
            source.popup = payload("1");
            tryCompare(island, "displayingNotification", true);
            verify(island.width > island.restingWidth);
            verify(island.height > island.restingHeight);
            source.popup = ({});
            tryCompare(island, "stateName", "idle");
            tryCompare(island, "width", island.restingWidth);
            const surface = findChild(island, "notificationIsland");
            tryCompare(surface, "opacity", 0);
            verify(!surface.visible);
        }
        function test_respectsAnExistingHigherPriorityState(): void {
            const island = createTemporaryObject(islandComponent, testRoot);
            verify(island.requestState("authorization", 7));
            source.popup = payload("2");
            tryCompare(source, "paused", true);
            compare(island.stateName, "authorization");
            island.returnToIdle();
            tryCompare(island, "displayingNotification", true);
            compare(island.stateName, "notification");
            compare(source.paused, false);
        }
        function test_clickOpensTheSelectedNotificationAndAdvances(): void {
            const island = createTemporaryObject(islandComponent, testRoot);
            clicked.target = island;
            source.popup = payload("3");
            tryCompare(island, "displayingNotification", true);
            mouseClick(island, 100, 40);
            tryCompare(clicked, "count", 1);
            compare(clicked.signalArguments[0][0], "3");
            compare(source.advanced, 1);
        }
        function test_lockRemovesEvenRetainedFadeContent(): void {
            const island = createTemporaryObject(islandComponent, testRoot);
            source.popup = payload("4");
            tryCompare(island, "displayingNotification", true);
            source.locked = true;
            source.popup = ({});
            tryCompare(island, "displayingNotification", false);
            verify(!island.notification.body);
        }
        function test_ribbonExpandsDownwardWithoutChangingItsReservedHeight(): void {
            const ribbon = createTemporaryObject(ribbonComponent, testRoot);
            const resting = ribbon.restingHeight;
            const island = findChild(ribbon, "ribbonCenter");
            verify(island !== null);
            source.popup = payload("5");
            tryCompare(island, "displayingNotification", true);
            compare(ribbon.restingHeight, resting);
            verify(island.mapToItem(ribbon, 0, 0).y >= 0);
            verify(ribbon.implicitHeight > resting);
        }
    }
}
