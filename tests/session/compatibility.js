// SPDX-License-Identifier: GPL-3.0-or-later
// Loaded only into the private cloud KWin by installed-client.sh.
function reportCompatibility() {
    const windows = workspace.windowList();
    for (const window of windows) {
        const name = String(window.resourceClass).toLowerCase();
        if (name.includes("gnome.calculator") || name.includes("gnome-calculator"))
            window.frameGeometry = {x: 120, y: 150, width: 480, height: 600};
        else if (name.includes("kcalc"))
            window.frameGeometry = {x: 760, y: 150, width: 480, height: 600};
    }
    print("OWODE_COMPAT_WINDOWS:" + JSON.stringify(windows.map(window => ({
        caption: window.caption, appId: String(window.resourceClass), pid: window.pid,
        normal: window.normalWindow, desktop: window.desktopWindow, dock: window.dock
    }))));
}
workspace.windowAdded.connect(reportCompatibility);
reportCompatibility();
