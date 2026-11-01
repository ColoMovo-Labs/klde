# Notifications and the Temporal Capsule

The system/native application path starts an in-process Qt D-Bus notification
server. The Visual Lab continues to use fixed, explicitly mock records and
claims no notification bus name. No notification text is logged or saved to disk.

## Protocol and ownership

`NotificationServer` implements the freedesktop Notifications interface on
`/org/freedesktop/Notifications`: Notify, CloseNotification, GetCapabilities,
GetServerInformation, NotificationClosed, ActionInvoked and the optional
ActivationToken signal. See the [notification specification](https://specifications.freedesktop.org/notification/latest-single/).
The declared compatibility version is 1.2. No empty/fabricated activation token
is sent; compositor-issued activation-token/focus forwarding remains a follow-up.
Clients must not depend on the optional signal. Inline replies and sound are
not advertised or implemented.

Service registration neither replaces nor queues behind another owner. A
conflict leaves an empty, read-only center with an explanation: the standard
interface offers no way to read another daemon's history. It does not show mock
history as if it came from the other service. The existing daemon keeps running.
Internal lock-state slots are not exported over D-Bus.

Capabilities are body, body-markup, actions, icon-static and persistence. Markup
is parsed as a small XML subset; only bold, italic, underline and safe links
survive. Image tags become their alt text; external resources are never loaded.
The center opens http/https/mailto links only on an explicit click. Image-data
is checked for type, dimensions, stride, channels and byte bounds. Local images
are size checked, and retained thumbnails are limited to 128 pixels per side.
Payloads and the in-memory history are bounded (100 records); oldest records
removed for capacity emit the standard undefined reason 4.

IDs increase within the server lifetime. Replacing an existing notification
from the same sender updates its record atomically, renews its icon revision
and marks it unread. Stale/unmatched replacement IDs create a fresh record;
notifications belonging to another sender are not overwritten. Close, expiry,
dismissal and action signals follow the record's lifecycle. A resident action
keeps its record; a transient record is removed after presentation and is not
kept as history. The normal default retains history until dismissal, while the
popup retracts separately. Critical notifications have no automatic expiry.

## Presentation and privacy

The existing SystemIsland priority machine is reused. Normal notifications
queue behind the current popup and behind higher priority island states. A
normal popup retracts after 4.5 seconds; hovering pauses both that countdown
and an explicit notification expiry. Critical popups require an explicit
close or navigation action. DND suppresses popups without replaying a backlog
when disabled; unread counts remain available. Notifications received while
locked are counted without exposing their bodies or replaying them on unlock.

The server subscribes to the real org.freedesktop.ScreenSaver ActiveChanged
signal and queries GetActive at startup. Until the service confirms an unlocked
state, popups remain suppressed. Older replies cannot override a newer lock
signal. Body roles are redacted while locked; retained fade content is cleared.
KWin/KScreenLocker remains the lock/security boundary.

The capsule grows downward into a Glass notification card using owoDE's
finite spring tokens, with a short opacity transition for reduced motion and
software rendering. Hover, actions and a click through to the selected center
record are wired to the same model. Wide layouts show a separate unread-message
capsule; condensed layouts keep a bell/count in the session group. The center
uses application grouping, per-item dismissal, clear-all and an empty state.
Its informational/profile fixture is hidden in native mode.

The center's layout host keeps the resting capsule dimensions. The native
ribbon window can grow, while its exclusive zone and popup/widget origin stay
at the normal ribbon height. Notifications do not reserve extra work area or
push maximized windows down. These are distinct properties, not a screenshot-only
reordering.

## Verification

- `notification-service`: private D-Bus server/client/locker fixture; real wire
  methods and signals, replacement, expiration, actions/resident, image data,
  hover, DND/privacy and ownership conflict.
- `tst_notification_island.qml`: expansion/collapse, priority, navigation, privacy,
  and downward expansion without changing the ribbon's resting height.
- `OWODE_CLOUD_NOTIFICATION_TEST=1 bash tools/notification-smoke.sh build/fedora artifacts/notifications-native`:
  isolated Xvfb + D-Bus + nested KWin, actual system-mode shell, synthetic real
  Notify/CloseNotification calls, screenshots and Wayland role/size/zone evidence.
- Frozen light/dark mock screenshots use `--island-state notification` with
  `--smoke-test --audit-idle`. Mock popups have no live countdown, so screenshots
  and idle-frame checks remain deterministic.

Software rendering verifies correctness, not physical GPU performance. These
checks do not establish arbitrary-application focus, suspend/resume lock security
or full hardware daily-driver acceptance.

## Reference boundary

The owner's Dynamic Island interaction direction is a visual reference. The
implementation uses owoDE's existing Tokens, Monet roles, material components
and C++ model. No end-4, DankMaterialShell, Noctalia or other Quickshell source,
shader, shape path or styling code was imported, and Quickshell is not a
runtime dependency. Any future source reuse from those projects requires the
owner's prior review of the repository, license, exact files and justification.
