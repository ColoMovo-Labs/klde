# CircleCI and cloud-first development

CircleCI is the authoritative build, test, analysis and integration environment.
Local machines are primarily for editing, reviewing and committing. A local green
build does not replace a green cloud build. No local compilation or tests were
performed during the initial repository preparation.

## Configuration

All jobs use the Docker executor with `ubuntu:26.04`, resource class `medium` and
the same checkout/build paths. `.circleci/packages.txt` is the shared apt manifest.
The baseline uses distribution Qt rather than a downloaded vendor SDK. Ubuntu's
[Qt development package](https://packages.ubuntu.com/resolute/qt6-declarative-dev)
provides the current release stack; the CMake API floor is Qt 6.8, which is not
separately verified by this one-platform pipeline.

| Job | Purpose | Merge policy |
| --- | --- | --- |
| configure-build | CMake/Ninja, C++20, warnings, ccache, persist build tree | required |
| static-analysis | clang-format, qmlformat, qmllint, clang-tidy, REUSE and desktop-file metadata | required |
| unit-tests | Qt Test backend contracts and packaged QML startup without warnings | required |
| qml-tests | Qt Quick Test checks tokens and launcher keyboard interaction | required |
| integration-smoke | first rendered frame and capture on offscreen/software, Weston/Wayland/software, Xvfb/OpenGL/llvmpipe | required |
| packaging-check | staged CMake install and tar archive | informational until packaging matures |

Five downstream jobs reuse the build workspace. Dependency archives and compiler
outputs are cached; stale apt archives do not prevent apt from obtaining newer
versions. CMake/Ninja outputs are shared within a pipeline rather than reused from
an unrelated revision. Test jobs emit JUnit reports. Environment package/Qt/tool
versions, smoke logs and PNGs, and the install archive are retained as artifacts.

The Ubuntu tag and apt repositories receive updates. This is a distribution-following
baseline, not a bit-for-bit reproducibility claim. Record an image digest and adopt
a dated package snapshot when reproducible release builds become necessary.
The apt manifest is currently outside Dependabot's supported update ecosystems;
`dependabot.yml` is explicitly inactive. Review dependencies monthly and enable
automation when a real supported manifest is added.

## Activation and first run

A committed configuration is not an active project. In the
[CircleCI project setup](https://circleci.com/docs/guides/getting-started/create-project/)
flow, select `ColoMovo-Labs/klde`, use the existing `.circleci/config.yml` on `main`,
and configure push and pull-request triggers. A GitHub App installation or repository
access may require organization-owner authorization. Do not embed a CircleCI token
in source, shell history or public logs.

After activation, record the pipeline URL and exact commit. Resolve configuration,
dependency and runtime failures in small commits. Inspect artifacts and runtime
warnings. Phase 1 begins only after the five core jobs pass for the minimal baseline.

For an existing token and supported project integration, the v2 API can inspect
pipelines. GitHub App projects may require their configured pipeline definition
and trigger endpoint; do not assume the legacy `gh/org/repo` trigger works for every
organization. Prefer the existing project trigger in the UI rather than inventing
an organization or pipeline ID.

## Required checks

Once CircleCI has reported to GitHub, inspect actual check-run/status names for
the tested commit. Enable a non-destructive protection/ruleset on `main` requiring
review and the five core checks. Preserve any existing protection; do not disable
it or replace organization rules. Require checks for the current head and block
force pushes/deletion. Do not add nonexistent check names that would deadlock PRs.

Applied after green baseline `418ea56`: `main` requires these exact contexts:

- `ci/circleci: configure-build`
- `ci/circleci: static-analysis`
- `ci/circleci: unit-tests`
- `ci/circleci: qml-tests`
- `ci/circleci: integration-smoke`

The rule requires an up-to-date branch, applies to administrators, and blocks
force pushes and deletion. A pull request is required; independent approving
review count is **zero** during sole-maintainer bootstrap. CODEOWNERS identifies
ownership but code-owner approval is not enforced. Raise the review count when
a second active maintainer can review; do not claim independent review occurred.

## Rendering evidence

The smoke helper waits for a real frame and fails if capture/startup times out.
Its watcher is active only in diagnostic mode. Ordinary startup has no timer-driven
render loop. Weston headless and llvmpipe are correctness environments; they do
not validate compositor desktop-layer behavior or Intel GPU performance.
See [Weston's backend/renderer documentation](https://wayland.pages.freedesktop.org/weston/toc/running-weston.html)
and [performance.md](performance.md).

The packaging artifact is a staged install tree, not a `.deb` or a complete Qt
runtime bundle. Installing it on an incompatible host is outside the baseline.
Debian packaging and test sessions arrive in later roadmap phases.

## Public pipeline inspection

For this public project, workflow/job and artifact lists were readable through
the v2 API without a token. Access requirements can differ for other projects.
Obtain the workflow ID from the GitHub status target URL and inspect:

```sh
curl --fail 'https://circleci.com/api/v2/workflow/<workflow-id>/job'
curl --fail 'https://circleci.com/api/v2/project/circleci/3oxaeukVqAvAfF4HxntS1j/LfN9QA8DUhSreeQV9xNCMg/<job-number>/artifacts'
```

Use the returned artifact URLs rather than guessing job IDs. Confirm the commit
and actual pipeline configuration, not just the pipeline number. The feature
pipeline uses its own all-source analysis and interaction-test configuration.

The current Ubuntu shared-Qt SDK emits CMake import-scan warnings about missing
static link targets for several distribution plugins. These warnings remain
visible in build logs. KLDE's embedded plugins are explicitly registered; the
Basic controls, SVG decoder and Effects runtime paths are exercised by startup
and rendering checks. Qt plugin bundling and `.deb` dependency generation remain
packaging work, rather than a claim that every scanned plugin was statically linked.
