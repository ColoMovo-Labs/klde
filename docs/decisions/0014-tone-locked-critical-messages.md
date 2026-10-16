# 0014 — Protect critical message tone

## Context

Cute wording can obscure security, privacy or destructive consequences.

## Decision

Reject voice overrides outside friendly/shell/ambient allowlists and always lock critical namespaces.

## Consequences

CI and runtime enforce the boundary; permission and legal copy stays precise in either voice.

## Alternatives considered

Editorial convention alone is easy to bypass; duplicating all critical text in each voice drifts.

## Future review conditions

Review any new override namespace or critical-message category.
