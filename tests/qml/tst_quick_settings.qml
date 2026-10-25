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
        id: popupComponent
        QuickSettings {}
    }
    TestCase {
        name: "CompactQuickSettings"
        when: windowShown
        property var popup
        function init(): void {
            Tokens.reducedMotion = true;
            Shell.mockScenarios.apply("laptop-balanced");
            popup = createTemporaryObject(popupComponent, testRoot, {
                parent: testRoot,
                y: 80
            });
            verify(popup !== null);
            popup.open();
            tryCompare(popup, "opened", true);
        }
        function cleanup(): void {
            popup.close();
            Tokens.reducedMotion = false;
        }
        function test_dndIsKeyboardOperableAndRemainsInSync(): void {
            const dnd = findChild(popup, "quickDnd");
            verify(dnd !== null);
            const before = Shell.state.snapshot.notifications.dnd;
            dnd.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(Shell.state.snapshot.notifications.dnd, !before);
            compare(dnd.selected, !before);
            Shell.state.requestValue("notifications.dnd", before);
            compare(dnd.selected, before);
        }
        function test_everydayControlsFitAt720p(): void {
            const form = findChild(popup, "quickSettingsForm");
            verify(form !== null);
            verify(form.implicitHeight <= popup.availableHeight);
            verify(findChild(popup, "quickMicrophone") !== null);
            verify(findChild(popup, "quickPowerProfile") !== null);
        }
        function test_networkButtonsRemainBalancedAcrossLanguages(): void {
            const wifi = findChild(popup, "quickWifi");
            const bluetooth = findChild(popup, "quickBluetooth");
            for (const locale of ["zh_CN", "en"]) {
                Shell.language.setLocale(locale);
                tryVerify(() => Math.abs(wifi.width - bluetooth.width) <= 1);
                verify(wifi.width >= 120);
            }
        }
    }
}
