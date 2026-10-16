# ADR 0005: Blur capabilities and fallback

Status: accepted direction; no effect implementation in Phase 0.

## Context

Wayland limits access to other-client content. Native backdrop effects depend on
the compositor, while owned-content GPU filtering has different permissions and costs.

## Decision

Define BlurBackend policy separating native backdrop, owned-content GPU blur and
translucent/opaque fallback. Prefer public Qt APIs and native compositor support.
Prototype only a bounded, cached, explicitly owned texture in Phase 1.

## Consequences

Blur cannot be guaranteed on every compositor. Static scenes must stop rendering.
Invalidation, output scale, hidden/screen-off lifecycle and allocation failure
are part of the contract. No private Qt API dependency is accepted by this ADR.

## Alternatives considered

Applying generic effects to every panel wastes resources. Capturing the desktop
to simulate blur breaks the intended security and performance model. A custom
Dual Kawase/QRhi backend is deferred until measurements justify it.
