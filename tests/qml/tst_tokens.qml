// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import KLDE.Shell

TestCase {
    name: "TokenContract"

    function cleanup() {
        Tokens.darkMode = false;
        Tokens.textScale = 1.0;
        Tokens.reducedMotion = false;
    }

    function test_themeChangesPropagate() {
        const initialBackground = Tokens.background.toString();
        Tokens.darkMode = true;
        verify(Tokens.background.toString() !== initialBackground);
        verify(Tokens.textPrimary.toString() !== Tokens.background.toString());
    }

    function test_textScalePropagates() {
        const initialSize = Tokens.body.pixelSize;
        Tokens.textScale = 2.0;
        compare(Tokens.body.pixelSize, initialSize * 2);
    }

    function test_reducedMotionSettlesImmediately() {
        Tokens.reducedMotion = true;
        compare(Tokens.motionFast, 0);
        compare(Tokens.motionNormal, 0);
        compare(Tokens.motionSlow, 0);
    }
}
