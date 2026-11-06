// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Owo.Visuals

Item {
    id: testRoot
    width: 1920
    height: 1080
    Component {
        id: landscapeComponent
        LockLandscape {
            wallpaperSource: Assets.root + "wallpapers/first-light.svg"
            foregroundSource: Assets.root + "wallpapers/snow-mountains.svg"
            clockFontSource: Assets.root + "fonts/rubik/Rubik[wght].ttf"
            timeText: "08:30"
            dateText: "Saturday, October 17"
        }
    }
    TestCase {
        name: "LockLandscape"
        when: windowShown

        function test_mountainsOccludeOnlyPartOfTheClock_data() {
            return [
                {
                    tag: "laptop",
                    width: 1366,
                    height: 768
                },
                {
                    tag: "desktop",
                    width: 1920,
                    height: 1080
                },
                {
                    tag: "reference",
                    width: 1440,
                    height: 900
                }
            ];
        }
        function test_mountainsOccludeOnlyPartOfTheClock(data) {
            const scene = createTemporaryObject(landscapeComponent, testRoot, {
                width: data.width,
                height: data.height,
                depthEnabled: false
            });
            verify(scene !== null);
            tryCompare(findChild(scene, "lockLandscapeBackground"), "status", Image.Ready);
            waitForRendering(scene);
            const plain = grabImage(scene);
            scene.depthEnabled = true;
            tryCompare(scene, "depthActive", true);
            waitForRendering(scene);
            const depth = grabImage(scene);
            const clock = findChild(scene, "lockAmbientClock");
            const position = clock.mapToItem(scene, 0, 0);
            let ink = 0;
            let covered = 0;
            for (let y = Math.max(0, Math.ceil(position.y)); y < Math.min(scene.height, position.y + clock.height); y += 3) {
                for (let x = Math.max(0, Math.ceil(position.x)); x < Math.min(scene.width, position.x + clock.width); x += 3) {
                    if (Qt.colorEqual(plain.pixel(x, y), scene.clockColor)) {
                        ++ink;
                        if (!Qt.colorEqual(plain.pixel(x, y), depth.pixel(x, y)))
                            ++covered;
                    }
                }
            }
            verify(ink > 100, "Clock actually rendered");
            verify(covered > 0, "Mountain overlaps the clock, rather than sitting behind it");
            verify(covered / ink < 0.25, "At least 75% of the clock ink remains visible: " + covered / ink);
        }
        function test_plainFallbackAndNarrowLayout() {
            const scene = createTemporaryObject(landscapeComponent, testRoot, {
                width: 360,
                height: 640,
                foregroundSource: ""
            });
            verify(scene !== null);
            compare(scene.depthActive, false);
            const clock = findChild(scene, "lockAmbientClock");
            verify(clock.width <= scene.width);
            verify(clock.y >= 0);
            const date = findChild(scene, "lockLandscapeDate");
            verify(date.y >= clock.y + clock.height);
            verify(date.y + date.height < scene.height);
        }
        function test_clockHonorsEffectPolicy() {
            const scene = createTemporaryObject(landscapeComponent, testRoot, {
                width: 1440,
                height: 900,
                transparencyEnabled: true
            });
            verify(scene !== null);
            for (const quality of [1, 2, 3]) {
                scene.blurQuality = quality;
                verify(scene.clockOpacity >= 0.86 && scene.clockOpacity < 1);
            }
            scene.blurEnabled = false;
            compare(scene.clockOpacity, 1);
            scene.blurEnabled = true;
            scene.transparencyEnabled = false;
            compare(scene.clockOpacity, 1);
            scene.transparencyEnabled = true;
            scene.blurQuality = 999;
            verify(isFinite(scene.clockOpacity));
            verify(scene.clockOpacity >= 0.86);
        }
    }
}
