# GitHub publication and administration

Target: `ColoMovo-Labs/klde`, public monorepo, default branch `main`.

Before creating, inspect the authenticated account, active organization membership
and the organization's complete repository list. A 404 can mean unavailable access;
it does not by itself prove absence. Stop on authentication/network failures. Never
push over an existing repository as a bootstrap shortcut.

## Exact publication commands

Run from this prepared Git repository with authenticated GitHub CLI access:

```sh
gh auth status
gh api user --jq .login
gh api user/memberships/orgs/ColoMovo-Labs --jq '{state, role}'
gh repo list ColoMovo-Labs --limit 1000
gh repo view ColoMovo-Labs/klde
```

Only if the authorized organization listing confirms `klde` is absent:

```sh
gh repo create ColoMovo-Labs/klde --public --source . --remote origin \
  --description 'Experimental Qt 6 Linux desktop shell with expressive design and a flexible floating/tiling vision'
git push -u origin main
```

If creation succeeded but pushing failed, inspect `origin` and retry the push;
do not repeat creation or force-push. If a repository already exists, fetch and
inspect its branches/history, then integrate through a topic branch and pull request.

Configure the requested topics and create missing labels without overwriting
existing label definitions:

```sh
gh repo edit ColoMovo-Labs/klde \
  --add-topic linux --add-topic desktop-environment --add-topic qt \
  --add-topic qt6 --add-topic qml --add-topic wayland --add-topic ubuntu \
  --add-topic ubuntu-kylin --add-topic ukui --add-topic open-source \
  --add-topic desktop-shell --add-topic kemono
python3 tools/create-labels.py
```

The label helper's default mode is a read-only plan. Use `--apply` to create
only missing labels after reviewing the plan. Label names and descriptions live
in `.github/labels.json`; no speculative issue backlog is automatically opened.

## Review and reporting setup

`CODEOWNERS` initially names `@ColoMovo`, the verified organization administrator.
Establish real maintainer teams before expanding it. Enable required review/core
checks after the first CircleCI run reports their actual names; see
[circleci.md](circleci.md). Do not enable destructive settings or rewrite history.

Verify a private security-reporting channel and a separate conduct contact before
claiming those channels are monitored. GitHub private vulnerability reporting can
be enabled for the repository; no public email address is invented in this baseline.
All changes to organization access, installed-app permissions and secrets remain
explicit administrative actions.

## Verification

```sh
gh repo view ColoMovo-Labs/klde --json nameWithOwner,url,visibility,defaultBranchRef,repositoryTopics
git ls-remote origin refs/heads/main
gh api repos/ColoMovo-Labs/klde/commits/main/check-runs --jq '.check_runs[] | {name, status, conclusion}'
gh api repos/ColoMovo-Labs/klde/commits/main/status --jq '{state, statuses: [.statuses[] | {context, state}]}'
```

Compare the remote branch hash with the local commit. A pushed CI configuration
is not a green run; use the remote status and pipeline evidence.
