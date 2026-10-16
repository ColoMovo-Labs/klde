# Roadmap

Phases describe acceptance gates, not dates or release promises.

| Phase | Scope | Exit evidence |
| --- | --- | --- |
| 0 — Foundation | Public repository, license/provenance, architecture/design, contribution workflow, CircleCI, minimal Qt executable and startup tests | repository and CI configured; all core jobs pass for an identified commit; baseline reviewed |
| 1 — Shell prototype | Own token system, dock, search launcher, quick settings, weather widget, workspace indicator; mock data; bounded owned-content blur experiment | coherent Qt prototype, keyboard tests, light/dark and opaque/reduced-motion review, finite rendering verified |
| 2 — System services | Event-driven audio, network, Bluetooth, power, applications and notifications | reconnect/error tests; explicit capability handling; no private data in default logs |
| 3 — Kylin integration | Evaluate Ubuntu Kylin host services through adapters | documented package/API/license audit; works without copied UKUI UI; normal Ubuntu fallback verified |
| 4 — Session integration | Login entry, startup/shutdown ordering, output/suspend lifecycle, portals and policy agents | isolated test session, recovery procedure, no duplicate host daemons; secure lock handling separately reviewed |
| 5 — Window management | Existing compositor adapter; per-workspace defaults, per-window floating, application rules, remembered geometry | capability-based integration tests; reconnect and multi-output validation; compositor choice justified by ADR |
| 6 — Settings center | Input, appearance, accessibility and effect policies | persistent settings schema, migration and permission handling; scalable keyboard-accessible UI |
| 7 — Packaging | Debian packaging, dependencies, upgrade/remove behavior, source/license delivery | reproducible package metadata, install/remove tests in disposable Ubuntu environments |
| 8 — Experimental remix | Optional installation image after session and packaging mature | documented provenance, upgrade/security ownership and recovery; clearly experimental branding |

Scrolling tiling and additional algorithms are research extensions after a basic
floating/tiling adapter works. They must not dictate a premature compositor fork.
Notification center, OSD, desktop widgets and session UI grow with actual service
capabilities rather than appearing as a collection of disconnected demonstrations.

Current state: Phase 0 is published at `ColoMovo-Labs/klde`. All six CircleCI jobs
passed for baseline `418ea56`; the Phase 1 build gate is satisfied.
See [the phase-0 handoff](docs/development/phase-0.md).
