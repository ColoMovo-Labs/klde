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
| unit-tests | Qt Test loads the packaged QML module and rejects QML warnings | required |
| qml-tests | Qt Quick Test checks live theme, scaling and reduced-motion token behavior | required |
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

Until this is applied remotely, “CI required before merge” is documented policy,
not verified technical enforcement. Record what is actually enabled in
[phase-0.md](phase-0.md).

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
