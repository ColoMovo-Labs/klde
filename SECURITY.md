# Security

KLDE currently has an unreleased Phase 0 baseline and no supported stable releases.
Fixes target the development branch. A version number is not a production security
or compatibility guarantee.

Do not disclose exploit details, credentials or private user content in a public
issue. Once the repository is public, use its **Security → Report a vulnerability**
feature if private reporting is enabled. Availability of that feature must be
confirmed; it is not enabled by adding this file. Otherwise contact an organization
owner through a public contact method they have designated for private reports.
A dedicated security address and response SLA have not yet been established.

Include affected commit/version, host distribution, session type, relevant service
versions, reproduction steps and impact. Use synthetic data and redact logs.
Maintainers should acknowledge reports, coordinate fixes and agree on disclosure
with the reporter; do not publish an unverified turnaround promise.

The shell is unprivileged. No root execution, credential store, hidden telemetry,
or automatic network request is part of Phase 0. Future privilege boundaries,
notification handling, secret-service use and plugin loading require review as
described in [ARCHITECTURE.md](ARCHITECTURE.md). Do not treat the preview window
as a login screen or secure session lock.
