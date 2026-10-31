// SPDX-License-Identifier: GPL-3.0-or-later
// Disposable guest only: independent KWin role/application observation.
function report() {
    const windows = workspace.windowList();
    print("OWODE_VM_STATE:" + JSON.stringify(windows.map(w => ({
        id: String(w.internalId), appId: String(w.resourceClass),
        caption: w.caption, pid: w.pid, normal: w.normalWindow,
        desktop: w.desktopWindow, dock: w.dock, active: w.active,
        geometry: {x: w.frameGeometry.x, y: w.frameGeometry.y,
                   width: w.frameGeometry.width, height: w.frameGeometry.height}
    }))));
}
workspace.windowAdded.connect(report);
workspace.windowRemoved.connect(report);
workspace.windowActivated.connect(report);
report();
