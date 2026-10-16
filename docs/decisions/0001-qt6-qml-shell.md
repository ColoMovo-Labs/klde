# ADR 0001: Qt 6 / QML shell

Status: accepted for the initial shell.

## Context

KLDE needs native desktop rendering, expressive interaction and a small runtime.
The first distribution target is Ubuntu Kylin / Ubuntu 26.04.

## Decision

Use Qt 6.8+, QML / Qt Quick, C++20 and CMake. Embed one small shell QML module
and use distribution Qt libraries. Python is tooling only. No browser engine or
Node.js shell runtime is introduced.

## Consequences

Qt model/property boundaries and public APIs are the baseline. Distribution Qt
versions are recorded in CI; minimum-version portability needs a later CI lane.
QML accessibility, scene-graph lifecycle and runtime imports require direct tests.

## Alternatives considered

Electron/CEF/web frontends are excluded by project requirements. A multi-language
Rust/C++ core adds cost before a demonstrated need. Reusing an entire existing
shell would constrain the intended identity and architecture.
