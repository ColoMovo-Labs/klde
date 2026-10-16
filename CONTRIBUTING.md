# Contributing

KLDE is early-stage. Read the architecture, design and decision records before
changing boundaries or introducing dependencies. Use issues for bugs, features,
design proposals and performance reports. Keep discussion respectful and evidence-based.

## Workflow

1. Open an issue for substantial work and describe the observable problem.
2. Work on a topic branch; keep commits focused and understandable independently.
3. Submit a small pull request using the template. Include motivation, changed
   behavior, validation, screenshots for actual UI changes and known limitations.
4. Wait for CircleCI and review. Address failures on the same branch.
5. Merge only after core CI is green for the current head and a maintainer approves.

CircleCI is authoritative. Local build/test runs are optional and never a substitute
for the cloud result. Do not request that every contributor compile locally.
The exact job policy and initial protection setup are in
[circleci.md](docs/development/circleci.md). Until remote required checks are
enabled, the same rule is a maintainer policy, not claimed technical enforcement.

## Code and UI

Use C++20, public Qt 6 APIs, modern CMake, RAII and property bindings. Run
`clang-format` with the repository configuration; use `qmlformat` from the CI
Qt version for QML. System logic belongs in C++, behind an adapter when needed.
Prefer subscriptions and asynchronous APIs. Introduce a dependency or abstraction
only for a current consumer. Record significant choices in `docs/decisions`.

No shell runtime based on Electron, CEF, a browser frontend, Node.js or Python.
Python is acceptable for development tooling. Do not fork UKUI or a compositor
as a shortcut to implementing the shell UI.

QML components need accessible names, keyboard interaction, visible focus and
token-based visual values. Verify opaque and reduced-motion behavior. No idle
animation, high-frequency polling or silent network access.

## Tests and performance

Add tests for meaningful behavior and regressions. Keep the initial suite small.
Distinguish mock tests, headless rendering, nested Wayland and real desktop
integration. Screenshots show appearance; a successful build alone does not.
Software rendering is useful for correctness and regression comparison, not
representative GPU performance. Attach measurements with environment and method:
[performance.md](docs/development/performance.md).

## Licensing and provenance

Contributions are offered under the relevant existing file license. Retain
copyright notices; never relicense someone else's code by replacing its header.
Code uses GPL-3.0-or-later; docs and original artwork use CC-BY-SA-4.0 unless
marked otherwise. Add new material to `REUSE.toml` or give it explicit SPDX
headers and include its license text. Document external sources and modifications
in [third-party.md](docs/legal/third-party.md). Disclose generated material and
review it as carefully as handwritten work. No franchise characters, copied
wallpapers or unlicensed icon sets.

## Maintainer setup

[github-setup.md](docs/development/github-setup.md) contains the target repository,
publication commands, topics, labels and required-check procedure. Code ownership
entries must refer to real people or teams with access. No nonexistent team is
silently treated as an active reviewer.
