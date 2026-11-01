# Status notifier host

The native/system shell runs a StatusNotifier host; previews do not register any
tray service or inspect the owner's applications. The small arrow opens a panel
of actual application-provided icons. Empty and passive items do not add a
permanent empty capsule. Icons have accessible application names and keyboard
focus; attention is a static state, without an idle animation loop.

`StatusNotifierWatcher` implements the small
[freedesktop watcher interface](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/StatusNotifierWatcher/).
It acquires `org.kde.StatusNotifierWatcher` only when free. With an existing
watcher, owoDE registers its own host name and follows its item list and signals;
it does not replace that watcher. Registrations are bounded to 64 items. A
client can register its own bus name or a path on its own connection, not another
process's name. Service/connection disappearance removes the corresponding icons.
Late property responses cannot resurrect removed or re-registered records.

Metadata and icon changes use bounded asynchronous Properties.GetAll requests.
Theme icons and bounded ARGB network-byte-order pixmaps are rendered through an
image provider; a per-application initial is the fallback. Untrusted titles are
plain text. There are no HTTP requests or tray contents saved to disk. A burst
while a request is in flight schedules one trailing refresh, not a polling loop.

Left, middle and right activation call the item's public Activate,
SecondaryActivate and ContextMenu methods. Some applications expect the host
to render their exported com.canonical.dbusmenu tree instead of implementing
ContextMenu; that menu-rendering extension remains a follow-up. This milestone
does not claim complete tray-menu compatibility or legacy XEmbed support.
Custom IconThemePath-only icons also need a resolver if no theme icon or pixmap
was supplied. Do not hide these limits behind fabricated generic application icons.

The item-change event is also useful for Fcitx's real indicator: its public
controller exposes queries but no dedicated current-method change signal.
Fcitx's notification item emits icon/tooltip updates when input contexts change.
This keeps the integration event driven. The input backend still queries its
controller, rather than interpreting arbitrary tray titles as input state.

Cloud tests run the watcher, a fixture application and an unrelated client on
a private D-Bus. They check ownership, registration, existing-watcher following,
metadata/status changes, activation methods and disappearance. Actual Fcitx and
Wayland input acceptance are recorded separately in input-methods.md.

The implementation was written for owoDE from the public D-Bus interfaces. No
end-4, DankMaterialShell, Noctalia or other Quickshell source was copied or
adapted; the shared owoDE tokens and components provide the presentation.
