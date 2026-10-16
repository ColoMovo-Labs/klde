# 0008 — Coordinate system and visual policy through Power Scenes

## Context

A power-profile dropdown describes only one service. KLDE also needs predictable
visual cost and user customization across hardware with different capabilities.

## Decision

Introduce a small PowerSceneController for Performance, Balanced and Power Saver.
Each carries system intent and validated visual settings. Default scenes retain
blur, using Low quality for Performance and Power Saver. User overrides are
explicit and resettable. The current system-profile implementation remains mock.

## Consequences

Presentation consumes a scene model, not sysfs or shell commands. Unsupported
hardware controls are absent. Effects can be applied locally while future system
adapters report pending/confirmed/failed state independently. Customizations are
session-only until persistent settings have a migration contract.

## Alternatives considered

A plain dropdown cannot describe visual policy. Direct UI writes to hardware
ignore authorization and partial failure. Implementing vendor power helpers before
capability research would add unverified behavior and privilege prematurely.
