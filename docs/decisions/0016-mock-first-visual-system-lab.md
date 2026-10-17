# 0016 — Mock-first Visual System Lab

## Context

A real service must not freeze unsettled shell behavior. The owner supplied dense
modular desktop and ambient/notification references that expose gaps in observability.

## Decision

Build one validated, event-driven scenario state, a modular ribbon, shared density
metrics and state-rich panels before further system integration. Keep all host
controls simulated. Make cloud screenshots and keyboard/state tests primary outputs.

## Consequences

Scenarios are deterministic and resettable. The UI can exercise hardware absence and
critical states safely; no timers manufacture activity. Existing real weather stays
an explicit experimental option and is revoked on scenario reset. New visual work
stacks on the prior reviewed foundation rather than rewriting its history.

## Alternatives considered

Scattered QML constants cannot validate cross-panel behavior. Wiring live services
first would make design iteration expensive. A third-party plugin ABI is premature.

## Future review conditions

Review real backend work only after the documented visual-lab exit checklist, manual
accessibility/IME work and representative hardware profiling have evidence.
