// SPDX-License-Identifier: GPL-3.0-or-later
"use strict";
const command = @COMMAND@;
let accepted = false;
const window = workspace.windowList().find(w => String(w.internalId) === command.window);
const desktop = workspace.desktops.find(d => String(d.id) === command.desktop);
if (command.operation === "workspace" && desktop) {
    workspace.currentDesktop = desktop;
    accepted = true;
} else if (window && (window.normalWindow || window.dialog) && !window.skipTaskbar) {
    if (command.operation === "activate") {
        if (window.desktops.length && !window.desktops.includes(workspace.currentDesktop))
            workspace.currentDesktop = window.desktops[0];
        window.minimized = false;
        workspace.activeWindow = window;
        accepted = true;
    } else if (command.operation === "close" && window.closeable) {
        window.closeWindow();
        accepted = true;
    } else if (command.operation === "move" && desktop) {
        window.desktops = [desktop];
        accepted = true;
    }
}
callDBus(@DESTINATION@, @OBJECT_PATH@, "org.owode.KWinBridge1", "commandFinished",
    @TOKEN@, command.id, accepted);
