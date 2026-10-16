# ADR 0002: Cloud-first CircleCI development

Status: accepted.

## Context

Contributor machines are editing environments with varied operating systems and
resources. Runtime performance still matters on ordinary Intel integrated graphics.

## Decision

CircleCI owns authoritative configure/build, analysis, unit/QML tests and smoke
validation. Local builds are optional. Use Ubuntu 26.04 containers, preserve
test/log artifacts and require core checks for merge after their names are observed.

## Consequences

A committed CI file is not a successful or activated pipeline. Publication,
integration access and triggers must be verified. Software-rendered jobs establish
correctness only; hardware performance needs a separate measurement process.

## Alternatives considered

Mandatory local builds conflict with the development model. GitHub Actions as a
second authoritative build system would duplicate work and contradict the requested
CI choice. A dedicated GPU runner is deferred until real workloads exist.
