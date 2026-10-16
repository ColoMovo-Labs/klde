# 0007 — Keep the desktop independent of a future distribution

## Context

KLDE may become the signature desktop of an Ubuntu LTS derivative, while also
serving ordinary Ubuntu, Fedora and source-build users. A custom ISO must not
become an implicit dependency of the desktop.

## Decision

Keep one upstream desktop monorepo. Ubuntu/Kylin is first-class, Fedora is a
serious secondary build target, and other distributions remain source targets.
Future distribution branding, defaults, app selection and update ownership belong
in downstream packaging. Detect services and hardware capabilities at runtime.

## Consequences

Cloud CI exercises independent Ubuntu and Fedora dependency stacks. Packaging
support is stated separately from source-build success. Distribution releases,
security ownership and ISO tooling need a later product decision; no date or
permanent future distribution name is promised.

## Alternatives considered

An ISO-only desktop couples upstream to one downstream policy. An immediate
repository split adds coordination without current consumers. Supporting every
distribution package equally at bootstrap exceeds verified infrastructure.
