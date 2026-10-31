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
// Geometry feeds only the dock's overlap test. Coalesce move/resize bursts so
// dragging a window sends a few snapshots per second, not one per frame.
const geometryTimer = new QTimer();
geometryTimer.singleShot = true;
geometryTimer.interval = 150;

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
        closeable: w.closeable, fullScreen: w.fullScreen,
        output: w.output ? String(w.output.name) : "",
        geometry: {x: w.frameGeometry.x, y: w.frameGeometry.y,
                   width: w.frameGeometry.width, height: w.frameGeometry.height}
    }));
    callDBus(destination, objectPath, "org.owode.KWinBridge1", "snapshot", token,
        JSON.stringify({schema: 1, sequence: ++sequence, desktops: desktops,
            currentDesktop: desktopId(workspace.currentDesktop), windows: windows}),
        function () {
            sending = false;
            if (dirty) schedule();
        });
}
function scheduleGeometry() {
    if (!geometryTimer.active) geometryTimer.start();
}
function watch(window) {
    // Only state that feeds shell models is observed. Paint/cursor changes are
    // ignored; geometry changes are coalesced by geometryTimer.
    for (const name of ["captionChanged", "desktopFileNameChanged", "desktopsChanged",
                        "minimizedChanged", "skipTaskbarChanged", "stackingOrderChanged",
                        "closeableChanged", "fullScreenChanged", "outputChanged"]) {
        if (window[name]) window[name].connect(schedule);
    }
    if (window.frameGeometryChanged) window.frameGeometryChanged.connect(scheduleGeometry);
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
geometryTimer.timeout.connect(schedule);
workspace.windowAdded.connect(watch);
workspace.windowRemoved.connect(schedule);
workspace.windowActivated.connect(schedule);
workspace.currentDesktopChanged.connect(schedule);
workspace.desktopsChanged.connect(watchDesktops);
workspace.windowList().forEach(watch);
watchDesktops();
