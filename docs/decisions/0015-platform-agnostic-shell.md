# 0015 — Keep platform APIs out of presentation

## Context

Display-specific control and ordinary QML presentation have different portability boundaries.

## Decision

Use common QPA observations and typed backends; reserve native Wayland/X11 adapters for actual consumers.

## Consequences

No raw display handles in QML; unsupported operations report unavailable rather than pretend success.

## Alternatives considered

Direct XCB calls are not portable; raw Wayland throughout the UI locks architecture prematurely.

## Future review conditions

Review with real surface hosting, global shortcuts, capture or compositor integration.
