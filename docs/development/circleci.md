# CircleCI and cloud-first development

CircleCI is the authoritative build, test, analysis and integration environment.
Local machines are primarily for editing, reviewing and committing. A local green
build does not replace a green cloud build. No local compilation or tests were
performed during the initial repository preparation.

## Configuration

Ubuntu jobs use the Docker executor with `ubuntu:26.04`, resource class
`medium` and matching checkout/build paths. `.circleci/packages.txt` is their
shared development apt manifest. `fedora-build` uses a separate `fedora:44`
executor and `.circleci/fedora-packages.txt`. Both use distribution Qt rather
than a downloaded vendor SDK. The CMake API floor is Qt 6.8; current distribution
builds do not separately verify that minimum version.

| Job | Purpose | Merge policy |
| --- | --- | --- |
| configure-build | Ubuntu CMake/Ninja, C++20, warnings, ccache, persist build tree | existing required check |
| static-analysis | clang-format, qmlformat, qmllint, clang-tidy, REUSE and desktop-file metadata | existing required check |
| unit-tests | Qt Test backend contracts and packaged QML startup without warnings | existing required check |
| qml-tests | Qt Quick Test tokens and keyboard interaction | existing required check |
| integration-smoke | offscreen/software, Weston/Wayland/software, Xvfb/OpenGL/llvmpipe | existing required check |
| fedora-build | Independent Fedora 44 configure/build, full CTest and offscreen/software startup | require green before claiming Fedora acceptance |
| packaging-check | CPack `.deb`, generated ELF dependencies and matching source archive | require green before claiming package acceptance |
| deb-runtime | Clean Ubuntu container, apt dependency resolution, installed binary capture and package purge | require green before claiming package acceptance |

Ubuntu analysis/test/package-build jobs reuse the Ubuntu build workspace.
The Fedora job builds independently. The runtime package job attaches artifacts
but does not call the development `prepare` command or install Qt development
packages. It installs the `.deb` through apt with no recommended packages so
missing QML/plugin dependencies are not masked by the build environment.

Ubuntu dependency archives and compiler outputs are cached; Fedora uses separate
DNF and compiler cache keys. CMake/Ninja outputs are shared within a pipeline
rather than reused from an unrelated revision. Test jobs emit JUnit reports.
Environment inventories and Qt/tool versions, smoke logs/PNGs and package/source
artifacts are retained. A configured job is not proof of success: record the
exact commit and results for the current head.

The Ubuntu/Fedora tags and their package repositories receive updates. This is a distribution-following
baseline, not a bit-for-bit reproducibility claim. Record an image digest and adopt
a dated package snapshot when reproducible release builds become necessary.
The apt/DNF manifests are currently outside Dependabot's supported update ecosystems;
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
force pushes/deletion. Do not add nonexistent check names that would deadlock PRs. New Fedora and
packaging contexts may be made required after their actual statuses are observed
green; preserve the original five contexts while extending protection.

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

The package artifact is an experimental `.deb` requiring compatible distribution
Qt, with a matching source archive. It is not a complete Qt runtime bundle, a
login session or a stable release. See [packaging scope](../../packaging/README.md)
and [platform coverage](platforms.md). llvmpipe measures correctness, not hardware
GPU performance.

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
and rendering checks. The `.deb` uses generated ELF dependencies plus explicit runtime QML/plugin
dependencies, checked in a clean container. It does not claim that every scanned
Qt plugin was statically linked or bundled.

## Language and display checks

Static analysis validates the embedded English/Chinese catalogs, duplicate IDs,
required strings, placeholders and sparse Cute overrides with protected namespaces.
The original Fcitx theme configuration and referenced SVG files receive structural
checks; native candidate rendering is not exercised by that check.

Integration runs the same Qt Quick interaction suite under Weston/Wayland and
Xvfb/XCB in addition to offscreen CTest. Captures include Chinese, English, Cute,
input and language settings. Distribution Noto CJK/emoji packages are declared
for Ubuntu and Fedora; startup tests verify a Chinese glyph. This does not replace
interactive IME validation, XWayland integration, text-scale or hardware profiling.
No real Fcitx engine is required or launched by these mock cloud tests.
