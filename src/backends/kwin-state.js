// SPDX-License-Identifier: GPL-3.0-or-later
// Original owoDE adapter. Placeholders are serialized JSON strings, never code
// obtained from an application. This script runs only in the selected KWin.
"use strict";
const destination = @DESTINATION@;
const objectPath = @OBJECT_PATH@;
const token = @TOKEN@;
const timer = new QTimer();
timer.singleShot = true;
timer.interval = 0;
let sequence = 0;
let sending = false;
let dirty = false;
const watchedDesktops = new Set();

function desktopId(desktop) { return desktop ? String(desktop.id) : ""; }
function schedule() {
    dirty = true;
    if (!sending && !timer.active) timer.start();
}
function publish() {
    dirty = false;
    sending = true;
    const desktops = workspace.desktops.map(d => ({id: desktopId(d), name: String(d.name)}));
    const windows = workspace.stackingOrder.filter(w =>
        (w.normalWindow || w.dialog) && !w.skipTaskbar && !w.deleted
    ).map(w => ({
        id: String(w.internalId), applicationId: String(w.desktopFileName),
        resourceClass: String(w.resourceClass), resourceName: String(w.resourceName),
        title: String(w.caption).slice(0, 2048), active: w === workspace.activeWindow,
        minimized: w.minimized, desktops: w.desktops.map(desktopId),
        closeable: w.closeable
    }));
    callDBus(destination, objectPath, "org.owode.KWinBridge1", "snapshot", token,
        JSON.stringify({schema: 1, sequence: ++sequence, desktops: desktops,
            currentDesktop: desktopId(workspace.currentDesktop), windows: windows}),
        function () {
            sending = false;
            if (dirty) schedule();
        });
}
function watch(window) {
    // Only state that feeds shell models is observed; geometry/paint/cursor
    // changes deliberately don't send traffic while a window is being moved.
    for (const name of ["captionChanged", "desktopFileNameChanged", "desktopsChanged",
                        "minimizedChanged", "skipTaskbarChanged", "stackingOrderChanged",
                        "closeableChanged"]) {
        if (window[name]) window[name].connect(schedule);
    }
    schedule();
}
function watchDesktops() {
    for (const desktop of workspace.desktops) {
        const id = desktopId(desktop);
        if (!watchedDesktops.has(id)) {
            watchedDesktops.add(id);
            desktop.nameChanged.connect(schedule);
        }
    }
    schedule();
}
timer.timeout.connect(publish);
workspace.windowAdded.connect(watch);
workspace.windowRemoved.connect(schedule);
workspace.windowActivated.connect(schedule);
workspace.currentDesktopChanged.connect(schedule);
workspace.desktopsChanged.connect(watchDesktops);
workspace.windowList().forEach(watch);
watchDesktops();
