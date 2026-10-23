# GitHub / CircleCI and CNB mirror

The public project keeps GitHub and CircleCI as its existing source and
authoritative build path:

- GitHub: `https://github.com/ColoMovo-Labs/klde`
- CircleCI: the existing `.circleci/config.yml` and project checks
- CNB mirror: `https://cnb.cool/ColoMovo-lab/owo_desktop_envirment_owoDE`

CNB is an additional public code host and a Fedora 44 cloud validation path. It
does not replace GitHub branch protection, GitHub issue/PR history or CircleCI's
authoritative Qt/CMake matrix. The root `.cnb.yml` installs the Fedora Qt and
LayerShellQt development packages, configures/builds the project, runs CTest,
and checks the public README/CircleCI entry points. It does not claim to
reproduce every CircleCI job, packaging check or real KWin compositor test.

## Migration boundary

The CNB repository was created as a public empty repository under the project
owner's account. A mirror push should include the current branches and tags,
while the GitHub `origin` remote remains unchanged:

```sh
git remote add cnb https://cnb.cool/ColoMovo-lab/owo_desktop_envirment_owoDE
git push cnb --all
git push cnb --tags
```

The CNB HTTPS token is a user credential and must be created in CNB's account
settings with only the repository read/write scope required for this mirror.
Do not commit it, put it in a URL, or copy it into a public build log. If Git
asks for credentials, use the token as the HTTPS password through the user's
credential manager. GitHub remains `origin`; do not replace it with CNB.
