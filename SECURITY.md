# Security

KLDE currently has an unreleased shell preview and no supported stable releases.
Fixes target the development branch. A version number is not a production security
or compatibility guarantee.

Do not disclose exploit details, credentials or private user content in a public
issue. Use [GitHub private vulnerability reporting](https://github.com/ColoMovo-Labs/klde/security/advisories/new)
or **Security → Report a vulnerability**. Private reporting was enabled and verified
through the GitHub API on 2026-10-16. If the feature is unavailable, contact an
organization owner through a public contact method designated for private reports.
A dedicated security address and response SLA have not yet been established.

Include affected commit/version, host distribution, session type, relevant service
versions, reproduction steps and impact. Use synthetic data and redact logs.
Maintainers should acknowledge reports, coordinate fixes and agree on disclosure
with the reporter; do not publish an unverified turnaround promise.

The shell is unprivileged. No root execution, credential store, hidden telemetry,
or automatic network request is part of the preview. Future privilege boundaries,
notification handling, secret-service use and plugin loading require review as
described in [ARCHITECTURE.md](ARCHITECTURE.md). Do not treat the preview window
as a login screen or secure session lock.

Online weather is an explicit opt-in exception to the offline default. It sends
an entered city and the connection IP to uapis.cn; consent is not persisted.
The transport retains TLS checks, refuses redirects, bounds response size and
never executes provider content. Weather strings are plain text, and neither
location-bearing URLs nor raw responses belong in logs. See
[weather boundaries](docs/architecture/weather.md).
