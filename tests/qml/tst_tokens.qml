// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import KLDE.Shell

TestCase {
    name: "TokenContract"

    function cleanup() {
        Tokens.darkMode = false;
        Tokens.accentChoice = "auto";
        Tokens.textScale = 1.0;
        Tokens.reducedMotion = false;
    }

    function luminance(color) {
        function linear(channel) {
            return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
        }
        return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
    }

    function test_primaryTextContrast() {
        for (const dark of [false, true]) {
            Tokens.darkMode = dark;
            for (const accent of ["auto", "teal", "lilac", "apricot"]) {
                Tokens.accentChoice = accent;
                const foreground = luminance(Tokens.textOnPrimary);
                const background = luminance(Tokens.primary);
                const ratio = (Math.max(foreground, background) + 0.05) / (Math.min(foreground, background) + 0.05);
                verify(ratio >= 4.5, "Primary text contrast: " + dark + "/" + accent + " = " + ratio);
            }
        }
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
