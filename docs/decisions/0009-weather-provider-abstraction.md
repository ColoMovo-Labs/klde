<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
# ADR 0009: Explicit weather providers with offline defaults

Status: accepted for the experimental preview; live service acceptance remains open.

## Context

The widget currently uses synthetic weather. The next integration candidate is
uapis.cn, whose external service, quota, privacy terms and response format can
change independently of KLDE. A desktop widget must remain understandable when
offline or stale and must not disclose location as a side effect of launching
the shell.

## Decision

Keep `WeatherProvider` responsible for request/cancel and normalized readings or
failures. `WeatherService` owns explicit online consent, the current-city memory
cache, state and a bounded refresh/backoff schedule. Ship mock data as the default
and an experimental `UApisCnWeatherProvider` behind explicit city selection and
online consent. Use Qt Network with fixed HTTPS origin, no redirects or API keys,
timeouts and bounded payloads. QML presents typed service properties and never
performs HTTP or parses provider JSON.

Preserve existing ADR numbers; this extends the original foundation rather than
renumbering published architectural history. The observed contract, source links,
terms ambiguity, attribution and acceptance boundaries are recorded in
[the weather architecture](../architecture/weather.md).

## Consequences

The default preview remains usable without an account, location setting or
network request. A failed real fetch stays visibly unavailable or stale instead
of fabricating fresh weather. Monthly quota exhaustion suspends requests until
explicit user action. CI uses synthetic fixtures and provider/clock injection,
so test success does not imply production API availability. There is no durable
cache, credential handling or automatic geolocation in this stage.

Online access exposes the configured city and source IP to an external provider.
Remote observations retain their original rights; shipping an adapter does not
settle commercial bundling or redistribution permission. Default-on integration
requires a current terms/data-rights review and live acceptance work.

## Alternatives considered

- HTTP and JSON in QML: mixes presentation with privacy, transport and retry policy.
- Permanently hardcode one provider's fields in the widget: prevents clean replacement.
- Auto-locate on startup: introduces an unexpected network and location disclosure.
- Real API calls in CI: adds shared-IP quota, external availability and privacy dependencies.
- A persistent weather daemon now: unnecessary process and storage complexity for one widget.
