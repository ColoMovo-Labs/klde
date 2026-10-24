# Temporal Capsule and System Island

The Temporal Capsule is the idle state of KLDE's central transient surface. The
`SystemIsland` component keeps the same visual anchor while allowing mock event
states for notification peeks, progress, privacy, authorization, media, device
and critical system activity.

State priority is explicit: critical, authorization, privacy, live activity,
device feedback, progress, notification, then idle time. A lower priority event
cannot replace an active higher priority event. Ordinary events return to the
clock after a finite timer; expanded details are opt-in and never run an idle
animation.

The current implementation is visual/mock only. Real notification, Polkit,
PipeWire, NetworkManager and screen-recording providers will connect through
interfaces later. Authorization remains a trusted-surface concept and is not
claimed to be secure in this phase.
