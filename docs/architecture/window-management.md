# Window management

Status: contract for later implementation. Phase 0 does not manage host windows.
KWin is the first engine candidate; see [the KWin adapter boundary](kwin-adapter.md).

## Interaction model

A workspace has a preferred layout policy. A window has placement state that may
override the policy. Floating and tiling coexist: workspaces 1–2 might float,
workspace 3 might tile, workspace 4 might mix both, and workspace 5 might use a
user-defined policy. The shell must not impose one global layout mode.

Preferred policy is distinct from effective arrangement. A tiled workspace may
contain a floating dialog. A compositor that cannot support a policy should report
it as unavailable rather than pretending the screen changed. Scrolling tiling and
multiple algorithms are future capabilities, not operations implemented by a mock.

The product modes are **Floating**, **Classic Tiling**, **Scrolling Tiling** and
**Mixed**. “Classic Tiling” is the neutral product name for a visible split or
master/stack arrangement; it is not a Hyprland integration. “Scrolling Tiling” is
the neutral name for a focus-following column arrangement; it is not a niri fork.

## WindowManagerBackend contract

Expose Qt models and asynchronous requests through stable backend-owned IDs.
Invalidate IDs and reconcile models when reconnecting; do not use window titles
as identity or expose native handles in QML.

| State or operation | Contract |
| --- | --- |
| Capabilities | workspace enumeration, activation, layout control, per-window floating, rules, remembered geometry, scrolling tiling are separate flags |
| Engine identity | engine family, build/API version, Qt/KF major versions, tile-tree support, script support, protocol capabilities |
| Workspace model | ID, accessible name, order, output association, preferred layout, effective layout, active state |
| Window model | ID, application ID, title, workspace/output IDs, floating state, activation state, optional permitted geometry |
| Activation/move | request ID and pending state; confirmation from compositor event or explicit rejection |
| Layout request | workspace ID and policy ID; validate support before requesting |
| Per-window override | window ID, floating/tiled intent; retain workspace default |
| Application rules | stable application identity, precedence, workspace/layout override; explicit persistence ownership |
| Remembered placement | logical geometry plus output identity/scale context; restore with bounds checks |

The interface should be small in Phase 1: mock workspace enumeration and selection,
layout-mode indicators and capability reporting are enough. Add methods when used.
The table reserves concepts, not mandatory abstract methods without consumers.

## Adapter candidates

Evaluate the KWin adapter first against documented window/workspace APIs, exact
engine family, distribution support, licensing and failure recovery. Upstream
KWin 6 and the deepin/Lingmo KWin lineage are separate compatibility profiles;
the adapter must not infer one from the other. Cutefish KWin6 plugins are useful
KDecoration3/script/effect references but their binary effects are rebuilt per
KWin ABI. wlroots remains a future alternative, not a universal window-management
protocol. Layer-shell placement alone does not grant window-management or tiling
control. Avoid treating an X11 geometry operation as a portable Wayland operation.

Layout may be performed by KWin's public script/tile API or an explicitly supported
policy API; the shell requests a policy. Classic Tiling can map to a KWin tile tree.
Scrolling Tiling first uses a KLDE-owned planner and only then maps to supported
KWin operations. There is no compositor implementation or fork in this phase.

## Rules and failure behavior

Define rule matching on desktop-file/application IDs; titles are optional conditions
with privacy implications. Distinguish transient dialogs from normal applications.
Before persistence, define precedence: explicit current-window override, application
rule, workspace policy, then backend default. Re-check this ordering with actual
compositor capabilities and user expectations.

If an output disappears, clamp restored floating geometry to a remaining usable
area; account for scale, reserved dock space and maximized/fullscreen state.
Unsupported requests produce accessible feedback. Reconnect must not repeatedly
apply a remembered layout to windows the user has since rearranged.

Contract tests should cover invalid IDs, rejected policies, delayed confirmation,
workspace deletion, output loss and reconnect reconciliation. Real integration
tests must verify actual host windows; changing mock model fields is not evidence
of tiling support.

## Display compatibility

Wayland is the future default; X11/XCB remains a compatibility path. Backend
capabilities, not the display name alone, determine supported operations. A KWin
engine does not require Plasma presentation. Native Wayland and XWayland client
behavior need separate interactive verification; an Xvfb startup is not proof of
window management or IME integration. See [display-protocols.md](display-protocols.md).
All workspace names and notices use the locale/voice model; layout IDs remain
stable and language independent.
