// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import KLDE.Shell
import KLDE.Backends

Item {
    id: testRoot
    width: 1440
    height: 900
    Component {
        id: studyComponent
        MaterialStudy {
            width: testRoot.width
            height: testRoot.height
        }
    }
    Component {
        id: surfaceComponent
        Surface {
            width: 200
            height: 80
        }
    }

    TestCase {
        name: "MaterialMotion"
        when: windowShown

        function maxProgress(spring) {
            let peak = 0;
            for (let i = 1; i < spring.curve.length; i += 2)
                peak = Math.max(peak, spring.curve[i]);
            return peak;
        }

        function test_springsAreFiniteMonotonicSplines() {
            const springs = [Tokens.springSpatialFast, Tokens.springSpatialMicro, Tokens.springHover, Tokens.springPopup, Tokens.springSpatial, Tokens.springSpatialSlow, Tokens.springEffectsFast, Tokens.springEffects, Tokens.springEffectsSlow];
            for (const spring of springs) {
                verify(spring.duration > 0 && spring.duration < 1000, "spring duration " + spring.duration);
                compare(spring.curve.length % 6, 0);
                // QEasingCurve preallocates ten BezierSpline segments; more corrupts the heap.
                verify(spring.curve.length / 6 <= 10, "at most ten spline segments");
                compare(spring.curve[spring.curve.length - 2], 1);
                compare(spring.curve[spring.curve.length - 1], 1);
                let previous = 0;
                for (let i = 0; i < spring.curve.length; i += 2) {
                    verify(isFinite(spring.curve[i]) && isFinite(spring.curve[i + 1]), "finite spring control points");
                    verify(spring.curve[i] >= previous, "time must not run backwards");
                    previous = spring.curve[i];
                }
            }
        }

        function test_onlyExpressiveSpatialSpringsOvershoot() {
            const level = Tokens.motionLevel;
            Tokens.motionLevel = 2;
            verify(maxProgress(Tokens.springSpatialFast) > 1.02);
            verify(maxProgress(Tokens.springSpatialMicro) < 1.06);
            verify(maxProgress(Tokens.springHover) < 1.04);
            verify(maxProgress(Tokens.springEffects) <= 1.0001);
            Tokens.motionLevel = 1;
            verify(maxProgress(Tokens.springSpatialFast) < 1.01);
            Tokens.motionLevel = 3;
            verify(Tokens.springSpatial.duration < Tokens.springCurve(0.9, 700).duration);
            Tokens.motionLevel = level;
        }

        function test_reducedMotionCollapsesSprings() {
            const reduced = Tokens.reducedMotion;
            Tokens.reducedMotion = true;
            compare(Tokens.springSpatial.duration, 0);
            compare(Tokens.springEffects.duration, 0);
            compare(Tokens.springStagger, 0);
            Tokens.reducedMotion = reduced;
        }

        function test_materialTiersAreComplete() {
            const keys = ["tint", "captureScale", "blur", "blurMax", "tintOpacity", "saturation", "grain", "rim", "specular", "refraction", "edge", "dispersion", "shadow"];
            for (const tier of ["mica", "acrylic", "glass"]) {
                for (const key of keys)
                    verify(Tokens.materials[tier][key] !== undefined, tier + "." + key);
            }
            verify(Tokens.materials.glass.refraction > 0);
            compare(Tokens.materials.mica.refraction, 0);
            compare(Tokens.materials.acrylic.refraction, 0);
        }

        function test_tieredSurfacesFallBackWithoutGpuEffects() {
            const classic = createTemporaryObject(surfaceComponent, testRoot);
            verify(!classic.tiered);
            for (const tier of ["mica", "acrylic", "glass"]) {
                const surface = createTemporaryObject(surfaceComponent, testRoot, {
                    material: tier
                });
                verify(surface.tiered);
                // The software scene graph used by this test has no shader path.
                compare(surface.materialActive, Shell.blur.ownedContentAvailable && surface.hasBlur);
                verify(Qt.colorEqual(surface.fill, Tokens.materials[tier].tint));
            }
        }

        function test_studyReplaysAndControlsAreKeyboardReachable() {
            const study = createTemporaryObject(studyComponent, testRoot);
            verify(study !== null);
            compare(findChild(study, "materialGlass").material, "glass");
            compare(findChild(study, "materialAcrylic").material, "acrylic");
            compare(findChild(study, "materialMica").material, "mica");
            compare(findChild(study, "materialFallbackNotice").visible, !Shell.blur.ownedContentAvailable);
            const revision = study.revealRevision;
            mouseClick(findChild(study, "materialReplay"));
            compare(study.revealRevision, revision + 1);
            const toggle = findChild(study, "materialExpressiveSwitch");
            verify(toggle.checked);
            mouseClick(toggle);
            verify(!toggle.checked);
            toggle.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Space);
            verify(toggle.checked);
            verify(toggle.visualFocus);
        }
    }
}
