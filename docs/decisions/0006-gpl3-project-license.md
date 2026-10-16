# ADR 0006: GPL-3.0-or-later code license

Status: accepted for original material in the baseline.

## Context

KLDE is intended for public development and may later integrate GPL desktop
infrastructure. Documentation/artwork need explicit and separate license metadata.

## Decision

Use GPL-3.0-or-later for original code/tooling, CC-BY-SA-4.0 for documentation and
original artwork unless marked otherwise. Include full license texts, SPDX path
annotations and a dependency/provenance inventory. No external shell source or
artwork is copied into Phase 0.

## Consequences

Future reuse requires a compatibility and notice review of exact files/revisions.
Dependencies retain their own licenses. Binary redistribution requires reviewing
the actual distributed combination; this decision alone does not establish compliance.
Trademark and character-art permissions are separate concerns.

## Alternatives considered

A permissive code license does not match the stated project preference. Giving
all artwork the code license obscures attribution/share-alike intent. Assuming
every GPL variant or upstream asset is interchangeable is unacceptable.
