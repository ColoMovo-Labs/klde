// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQml

// Deterministic wallpaper seeds for the KLDE Material Expressive palette.
//
// The first implementation deliberately uses authored seeds for each shipped
// wallpaper. This keeps startup offline, avoids a per-frame image analysis
// loop, and gives the design team stable tones to review. A future wallpaper
// backend can replace these seeds with cached pixel extraction without changing
// the role names consumed by Tokens.qml.
QtObject {
    readonly property var lightPalettes: ({
            "snow": ({
                    primary: "#1769a8",
                    onPrimary: "#ffffff",
                    primaryContainer: "#cbe7ff",
                    secondary: "#55647a",
                    secondaryContainer: "#dbe7f5",
                    tertiary: "#805b37",
                    tertiaryContainer: "#ffdcba",
                    background: "#edf5ff",
                    surface: "#f8fbff",
                    surfaceContainer: "#e1edf9",
                    surfaceElevated: "#ffffff",
                    outline: "#71869b",
                    textPrimary: "#17202a",
                    textSecondary: "#526171",
                    textDisabled: "#7d8b96",
                    shadow: "#254a70",
                    warning: "#805400",
                    success: "#2e6d4a"
                }),
            "abstract": ({
                    primary: "#5147c9",
                    onPrimary: "#ffffff",
                    primaryContainer: "#e4deff",
                    secondary: "#6f587d",
                    secondaryContainer: "#f0dff5",
                    tertiary: "#8f5260",
                    tertiaryContainer: "#ffdadd",
                    background: "#f4f1ff",
                    surface: "#fcfaff",
                    surfaceContainer: "#ece7fb",
                    surfaceElevated: "#ffffff",
                    outline: "#817b9b",
                    textPrimary: "#211d31",
                    textSecondary: "#625d72",
                    textDisabled: "#8b8799",
                    shadow: "#41327a",
                    warning: "#805300",
                    success: "#2c6d4b"
                }),
            "quiet": ({
                    primary: "#2b6e63",
                    onPrimary: "#ffffff",
                    primaryContainer: "#c8eee6",
                    secondary: "#56686a",
                    secondaryContainer: "#dcebea",
                    tertiary: "#7c5b35",
                    tertiaryContainer: "#ffddba",
                    background: "#edf8f6",
                    surface: "#f9fcfb",
                    surfaceContainer: "#deefec",
                    surfaceElevated: "#ffffff",
                    outline: "#738a87",
                    textPrimary: "#172321",
                    textSecondary: "#536563",
                    textDisabled: "#7f918f",
                    shadow: "#275c57",
                    warning: "#805400",
                    success: "#2c6d4b"
                }),
            "kemono": ({
                    primary: "#704ea3",
                    onPrimary: "#ffffff",
                    primaryContainer: "#eedcff",
                    secondary: "#5e628a",
                    secondaryContainer: "#e1e3ff",
                    tertiary: "#96536e",
                    tertiaryContainer: "#ffd9e6",
                    background: "#f7f1ff",
                    surface: "#fffaff",
                    surfaceContainer: "#eee5f7",
                    surfaceElevated: "#ffffff",
                    outline: "#887c9c",
                    textPrimary: "#241d2d",
                    textSecondary: "#665a70",
                    textDisabled: "#92869b",
                    shadow: "#543a7e",
                    warning: "#805300",
                    success: "#2c6d4b"
                })
        })

    readonly property var darkPalettes: ({
            "snow": ({
                    primary: "#9dceff",
                    onPrimary: "#003452",
                    primaryContainer: "#075078",
                    secondary: "#bdc9dd",
                    secondaryContainer: "#3d4a5e",
                    tertiary: "#f3bd8a",
                    tertiaryContainer: "#614321",
                    background: "#0e1a27",
                    surface: "#152536",
                    surfaceContainer: "#203449",
                    surfaceElevated: "#263d52",
                    outline: "#8b9bad",
                    textPrimary: "#e3f1ff",
                    textSecondary: "#c0cfdd",
                    textDisabled: "#8796a4",
                    shadow: "#06101b",
                    warning: "#f4c76f",
                    success: "#9dd6ae"
                }),
            "abstract": ({
                    primary: "#c8bdff",
                    onPrimary: "#2d237c",
                    primaryContainer: "#4039a0",
                    secondary: "#d7bee0",
                    secondaryContainer: "#4b3857",
                    tertiary: "#ffb9c5",
                    tertiaryContainer: "#6a3544",
                    background: "#171426",
                    surface: "#241d35",
                    surfaceContainer: "#322945",
                    surfaceElevated: "#3c3152",
                    outline: "#a49bb5",
                    textPrimary: "#f2ecff",
                    textSecondary: "#d1c6dd",
                    textDisabled: "#978da5",
                    shadow: "#0d0919",
                    warning: "#f2c36e",
                    success: "#9dd6ae"
                }),
            "quiet": ({
                    primary: "#9fd9cd",
                    onPrimary: "#003a33",
                    primaryContainer: "#14564d",
                    secondary: "#b9cccc",
                    secondaryContainer: "#3b4d4c",
                    tertiary: "#f1bd88",
                    tertiaryContainer: "#5e421f",
                    background: "#0c1a19",
                    surface: "#142724",
                    surfaceContainer: "#1e3935",
                    surfaceElevated: "#294842",
                    outline: "#869e99",
                    textPrimary: "#e1f5f0",
                    textSecondary: "#bdd4cf",
                    textDisabled: "#839894",
                    shadow: "#06100f",
                    warning: "#f4c76f",
                    success: "#9dd6ae"
                }),
            "kemono": ({
                    primary: "#d7b8ff",
                    onPrimary: "#3e1a69",
                    primaryContainer: "#55317c",
                    secondary: "#c6c6ee",
                    secondaryContainer: "#414264",
                    tertiary: "#ffb8d4",
                    tertiaryContainer: "#71364e",
                    background: "#1a1422",
                    surface: "#292039",
                    surfaceContainer: "#392d4b",
                    surfaceElevated: "#45375a",
                    outline: "#aa9ab2",
                    textPrimary: "#faedff",
                    textSecondary: "#d7c6dc",
                    textDisabled: "#9b899f",
                    shadow: "#0e0913",
                    warning: "#f4c76f",
                    success: "#9dd6ae"
                })
        })

    function paletteFor(wallpaper: string, dark: bool): var {
        const key = ["snow", "abstract", "quiet", "kemono"].indexOf(wallpaper) >= 0 ? wallpaper : "snow";
        return (dark ? darkPalettes : lightPalettes)[key];
    }
}
