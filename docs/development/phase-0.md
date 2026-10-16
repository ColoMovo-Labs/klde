# Phase 0 handoff

Prepared 2026-10-16. This document distinguishes source preparation from remote
publication and successful cloud execution. Update it only from observed results.

## Scope and repository

The starting workspace contained no project checkout or history. A new `klde`
monorepo was prepared independently; no existing project files were overwritten.
Target organization: `ColoMovo-Labs`. The authenticated GitHub account `ColoMovo`
has active administrator membership. The organization repository list and direct
repository lookup showed no existing `klde` before creation.

The editing host is Fedora 44 with Qt 6.11.2, CMake 4.3.0, GCC 16.2.1 and Ninja
1.13.2. These are inspection results, not the target build environment. No local
compilation, tests, static analysis or integration run was performed. Only source
editing, review and lightweight C++/QML formatting were used.

## Checklist

- [x] Independent-shell boundaries and compositor/UKUI strategy documented.
- [x] Design direction and complete initial token roles recorded.
- [x] README, architecture, design, roadmap and contribution/community/security files.
- [x] Six initial decision records, blur research, window-management and performance plans.
- [x] GPL-3.0-or-later code license; CC-BY-SA-4.0 documentation; provenance metadata.
- [x] GitHub issue/PR templates, CODEOWNERS, labels and explicit Dependabot status.
- [x] Six-job CircleCI configuration, dependency/cache strategy and artifact reporting.
- [x] Minimal Qt 6/C++20/CMake application, embedded QML module and seed tokens.
- [x] Initial Qt Test / Qt Quick Test and three smoke-rendering paths defined.
- [x] Public remote creation, twelve topics and all sixteen requested labels configured.
- [x] Five initial commits pushed to `main`.
- [x] CircleCI connected and first pipeline execution observed.
- [x] All six jobs green for `418ea56`; foundation runtime capture reviewed.
- [ ] Required remote checks and review protection enabled after check names exist.
- [x] Private security reporting enabled and verified through the GitHub API.
- [ ] A dedicated conduct contact established and verified.

## Published state

Repository: <https://github.com/ColoMovo-Labs/klde>, verified public, default branch
`main`. Initial source/test head: `d7b25e0`. Commits separate repository metadata,
project documents, CI, the minimal Qt build and the initial tests. A follow-up
documentation commit records publication evidence. Existing default labels were
preserved; only missing requested labels were created. No repository, branch or
release was deleted or force-pushed.

Before CircleCI activation, GitHub reported no check runs and an empty commit-status list.
The combined-status API returns `pending` for that empty list; this is **not**
evidence of a running CircleCI build. Required-check protection is not configured
until actual CircleCI check names are observed. Those names have now been observed
on the green baseline; the protection setup is the next administrative action.

## Validation history

The initial sandbox network errors falsely resembled invalid GitHub authentication.
Read-only checks outside the network-restricted sandbox confirmed working GitHub
credentials and organization access. No reauthentication is required for `gh`.

CircleCI and GitHub browser login were completed by the account owner. The `klde`
project has been created in the existing CircleCI organization `LoloVerse-Lab`
and connected to `ColoMovo-Labs/klde` using the GitHub App integration. It uses
the existing `.circleci/config.yml` on `main`, with PR-open/update, default-branch
push and tag-push triggers.

Pipeline 1 (`b68a017`, Qt 6.10.2 on Ubuntu 26.04) passed configure/build, static
analysis, Qt startup tests, all three rendering smoke paths and the install check.
Its QML suite failed the theme-change comparison. The follow-up test snapshots
color values as strings before mutation, rather than retaining a QML value reference.
Pipeline 2 validated the fix and passed **all six jobs** for full commit
`418ea566fd55d7f3248f4c5c5f29253b5e30f6db`. The minimal baseline gate is satisfied.

[First workflow](https://app.circleci.com/pipelines/circleci/3oxaeukVqAvAfF4HxntS1j/LfN9QA8DUhSreeQV9xNCMg/1/details?workflowId=70ad82ab-4a30-4347-9514-2ae6ff7d9e1a).

[Green baseline workflow](https://app.circleci.com/pipelines/circleci/3oxaeukVqAvAfF4HxntS1j/LfN9QA8DUhSreeQV9xNCMg/2/details?workflowId=175f9c3b-df61-41e5-9978-045d918ddf6f).
The actual [foundation capture](foundation-llvmpipe.png) was downloaded from the
first run's `integration-smoke` artifact and visually inspected. This verifies
the minimal window's rendering, not final shell polish or real GPU performance.

No CircleCI credential is stored in the repository. A GitHub CLI token is not
substituted for a CircleCI session.

## Gate

At this baseline, Phase 1 is not implemented. No dock, launcher, quick-settings panel, weather widget,
workspace controller, real backend or blur effect is claimed. The only window is
the deliberately small foundation surface. Phase 1 may now begin on a topic branch,
because the five core checks passed, per [circleci.md](circleci.md).

Publication steps and recovery commands are in [github-setup.md](github-setup.md).
`.deb` packaging, real desktop/session tests, screen-off integration, hardware
performance measurements, theme/contrast and screen-reader acceptance remain later work.
