// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import KLDE.Shell
import KLDE.Backends

Item {
    id: testRoot
    width: 1080
    height: 1000
    Component {
        id: centerComponent
        NotificationCenter {}
    }
    Component {
        id: candidateComponent
        CandidatePreview {}
    }
    Component {
        id: ambientComponent
        AmbientDesktop {
            width: 640
            height: 800
        }
    }
    Component {
        id: labComponent
        MockLab {}
    }
    Component {
        id: ribbonComponent
        StatusRibbon {
            width: testRoot.width
            height: implicitHeight
        }
    }
    Component {
        id: temporalComponent
        TemporalCapsule {}
    }
    Component {
        id: wallpaperComponent
        WallpaperEffectsSettings {}
    }
    Component {
        id: temporalPanelComponent
        TemporalSettings {}
    }
    TestCase {
        name: "VisualLabInteraction"
        when: windowShown
        function init(): void {
            Shell.mockScenarios.apply("laptop-balanced");
            Tokens.reducedMotion = true;
            Tokens.densityMode = 1;
        }
        function cleanup(): void {
            Shell.mockScenarios.apply("laptop-balanced");
            Tokens.reducedMotion = false;
            Tokens.densityMode = 1;
        }
        function test_desktopClockCanBeDisabledFromTheKeyboard(): void {
            const panel = createTemporaryObject(temporalPanelComponent, testRoot, {
                parent: testRoot
            });
            panel.open();
            tryCompare(panel, "opened", true);
            const choice = findChild(panel, "desktopModeChoice");
            choice.forceActiveFocus();
            keyClick(Qt.Key_Space);
            tryCompare(choice.popup, "opened", true);
            keyClick(Qt.Key_End);
            keyClick(Qt.Key_Return);
            compare(Shell.state.snapshot.appearance.ambient, true);
            compare(Shell.state.snapshot.appearance.focus, true);
            choice.forceActiveFocus();
            keyClick(Qt.Key_Space);
            tryCompare(choice.popup, "opened", true);
            keyClick(Qt.Key_Home);
            keyClick(Qt.Key_Return);
            compare(Shell.state.snapshot.appearance.ambient, false);
            compare(Shell.state.snapshot.appearance.focus, false);
            panel.close();
        }
        function test_ambientCompositionFitsShortSurfaces(): void {
            const ambient = createTemporaryObject(ambientComponent, testRoot, {
                width: 1366
            });
            const composition = findChild(ambient, "ambientComposition");
            verify(composition !== null);
            for (const height of [320, 420, 600, 900]) {
                ambient.height = height;
                wait(0);
                verify(composition.height <= height + 1, "Ambient height: " + height);
                verify(composition.y >= -1);
            }
        }
        function test_temporalStateAndCacheControls(): void {
            const capsule = createTemporaryObject(temporalComponent, testRoot);
            verify(capsule !== null);
            verify(Shell.mockScenarios.apply("rainy-evening"));
            compare(capsule.reading.phase, "rainy-evening");
            verify(capsule.rainy);
            verify(Shell.mockScenarios.apply("wallpaper-depth-enabled"));
            compare(Shell.wallpaperEffects.state.effectiveMode, "depth");
            Shell.wallpaperEffects.clearPreview();
            compare(Shell.wallpaperEffects.state.effectiveMode, "normal");
            const panel = createTemporaryObject(wallpaperComponent, testRoot, {
                parent: testRoot
            });
            verify(panel !== null);
            panel.open();
            tryCompare(panel, "opened", true);
            panel.close();
        }
        function test_ambientWeatherHonorsUnavailableState(): void {
            const ambient = createTemporaryObject(ambientComponent, testRoot);
            verify(Shell.mockScenarios.apply("weather-provider-error"));
            const label = findChild(ambient, "ambientWeather");
            verify(label !== null);
            compare(label.text, I18n.t("friendly.weather.unavailable"));
        }
        function test_layoutRequestsCrossTheQmlModelBoundary(): void {
            verify(Shell.state.requestValue("workspaces.layouts", [0, 1, 2, 3, 0]));
            compare(Shell.windowManager.workspaces[3].layout, 3);
            verify(!Shell.state.requestValue("workspaces.layouts", [false, 1, 2, 3, 0]));
            verify(!Shell.state.requestValue("workspaces.layouts", [null, 1, 2, 3, 0]));
            verify(!Shell.state.requestValue("workspaces.layouts", [0.5, 1, 2, 3, 0]));
            compare(Shell.windowManager.workspaces[0].layout, 0);
            verify(Shell.state.requestValue("workspaces.active", 4));
            compare(Shell.windowManager.activeWorkspace, "workspace-4");
        }
        function test_scenarioSelectorCanBeUsedFromTheKeyboard(): void {
            const panel = createTemporaryObject(labComponent, testRoot, {
                parent: testRoot
            });
            panel.open();
            tryCompare(panel, "opened", true);
            const selector = findChild(panel, "scenarioSelector");
            verify(selector !== null);
            selector.forceActiveFocus();
            keyClick(Qt.Key_Space);
            tryCompare(selector.popup, "opened", true);
            keyClick(Qt.Key_End);
            keyClick(Qt.Key_Return);
            tryCompare(selector.popup, "opened", false);
            compare(Shell.mockScenarios.activeId, "weather-extreme-cold");
            compare(Shell.state.snapshot.weather.temperature, -32);
            panel.close();
        }
        function test_dateUsesTheSelectedLocale(): void {
            Shell.language.setLocale("zh_CN");
            verify(I18n.date("2026-10-17T08:30:00", true).indexOf("周六") >= 0);
            Shell.language.setLocale("en");
            verify(I18n.date("2026-10-17T08:30:00", true).indexOf("Sat") >= 0);
        }
        function test_notificationClearPropagatesToState(): void {
            const panel = createTemporaryObject(centerComponent, testRoot, {
                parent: testRoot
            });
            verify(panel !== null);
            panel.open();
            tryCompare(panel, "opened", true);
            const clear = findChild(panel, "clearNotifications");
            verify(clear !== null);
            clear.forceActiveFocus();
            keyClick(Qt.Key_Space);
            compare(Shell.notifications.count, 0);
            compare(Shell.state.snapshot.notifications.count, 0);
            panel.close();
        }
        function test_candidateIsKeyboardSelectableWithoutHostInput(): void {
            const panel = createTemporaryObject(candidateComponent, testRoot, {
                parent: testRoot
            });
            panel.open();
            tryCompare(panel, "opened", true);
            panel.focusCandidate(1);
            keyClick(Qt.Key_Space);
            compare(panel.selectedIndex, 1);
            verify(Shell.state.requestValue("input.simplified", false));
            compare(panel.simplified, false);
            panel.close();
        }
        function test_ribbonWrapsAndRemainsBounded(): void {
            const ribbon = createTemporaryObject(ribbonComponent, testRoot);
            verify(ribbon !== null);
            for (const width of [640, 1024, 1366, 1600, 1920, 2560, 3440]) {
                ribbon.width = width;
                for (const density of [0, 1, 2]) {
                    Tokens.densityMode = density;
                    wait(0);
                    verify(ribbon.implicitHeight > 0);
                    verify(ribbon.implicitHeight < 250);
                    const center = findChild(ribbon, "ribbonCenter");
                    verify(center !== null);
                    const left = findChild(ribbon, "ribbonLeft");
                    const right = findChild(ribbon, "ribbonRight");
                    verify(left !== null);
                    if (!ribbon.stacked) {
                        verify(left.x + left.width <= center.x - Tokens.ribbonGroupGap + 1);
                        verify(right.x >= center.x + center.width + Tokens.ribbonGroupGap - 1);
                    } else {
                        verify(left.y >= center.y + center.height);
                        verify(right.y >= center.y + center.height);
                    }
                    for (const section of [left, right]) {
                        for (const id of ["context", "date", "workspaces", "telemetry", "connectivity", "session", "extras"]) {
                            const group = findChild(section, "ribbonGroup-" + id);
                            if (group && group.entries.length > 0) {
                                const position = group.mapToItem(ribbon, 0, 0);
                                verify(position.x >= section.x - 1, id + " starts inside lane");
                                verify(position.x + group.width <= section.x + section.width + 1, id + " ends inside lane");
                            }
                        }
                    }
                    console.info("axis-geometry", width, density, center.x + center.width / 2 - width / 2, "right-edge", right.x + right.width);
                    verify(right !== null);
                    verify(Math.abs(right.x + right.width - width) < 1);
                    verify(Math.abs(center.x + center.width / 2 - width / 2) < 1);
                    for (const section of ribbon.children) {
                        verify(section.x >= 0);
                        verify(section.x + section.width <= width + 1);
                    }
                }
            }
            const center = findChild(ribbon, "ribbonCenter");
            for (const id of ["context", "date", "notifications", "bluetooth"]) {
                verify(Shell.ribbon.setVisible(id, false));
                wait(0);
                verify(Math.abs(center.x + center.width / 2 - ribbon.width / 2) <= 1);
            }
            Shell.ribbon.reset();
            Shell.mockScenarios.apply("desktop-no-battery");
            compare(Shell.state.snapshot.capabilities.battery, false);
        }
    }
}
