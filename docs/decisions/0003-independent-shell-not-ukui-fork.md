# ADR 0003: Independent shell, selective UKUI compatibility

Status: accepted.

## Context

Ubuntu Kylin is the first host, and older UKUI/Kylin visuals inform the project's
atmosphere. Long-term installation on normal Ubuntu remains required.

## Decision

Implement KLDE UI independently. Prefer standard system services. Evaluate useful
UKUI host infrastructure behind replaceable adapters, with API/license audits.
Do not fork ukui-panel, the complete desktop, or an entire compositor.

## Consequences

The prototype coexists with the host desktop. Integration must avoid duplicate
daemons. Any copied source needs explicit provenance; there is no UKUI source
reuse in Phase 0.

## Alternatives considered

A UKUI theme is insufficient for the interaction goals. A wholesale fork creates
portability and maintenance burdens. Reimplementing every mature system service
would waste effort and create security/lifecycle risks.
