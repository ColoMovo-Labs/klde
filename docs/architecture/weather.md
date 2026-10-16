<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
# Weather providers and explicit online access

KLDE uses a provider boundary so its widget can remain useful with mock data,
without network access, and when a provider changes or disappears. The default
preview is the synthetic Snowline forecast. It sends no weather requests.

## Current implementation

```text
WeatherWidget → WeatherService → WeatherProvider
                                ├── MockWeatherProvider (default)
                                └── UApisCnWeatherProvider (experimental, explicit opt-in)
```

`WeatherService` exposes a normalized reading, availability, loading state,
attribution, stale state, an error message and the earliest permitted refresh.
The presentation does not construct URLs, parse provider JSON or schedule HTTP.
`enableOnline(city, language)` is the consent boundary; its caller must disclose
the provider, experimental status, external terms and transmission of the city
and source IP before invoking it. An empty city is rejected. `disableOnline()`
aborts pending work, drops the real reading and returns to explicitly labeled
mock data. No consent or location is persisted by this implementation.

The adapter is compiled in, but construction does not contact its endpoint.
Calling the adapter directly also requires `setNetworkConsent(true)` first.
There is no API key support, embedded organization credential, account login,
GPS lookup, automatic IP-based location lookup or background city search.
An enabled request necessarily exposes the user's network address to the
provider even when KLDE supplies the city explicitly.

## Provider contract researched on 2026-10-16

The [official weather reference](https://uapis.cn/docs/api-reference/get-misc-weather)
documents `GET https://uapis.cn/api/v1/misc/weather`. It accepts a city name or
administrative code; omitting both activates IP location. KLDE sends an explicit
`city` and `lang=en` or `lang=zh` and does not enable optional forecast modules.
The example success payload is a root JSON object with `city`, `weather`,
numeric Celsius `temperature` and `report_time`. High/low temperatures are
optional forecast fields, so their absence is not zero degrees. The timestamp
example lacks a timezone; KLDE preserves its text separately from UTC fetch time.

The same page describes the condition text as free form. Its sample calls the
icon field `weather_icon`, while its prose also uses `weather_code` and
`weathercode`. The adapter accepts those optional aliases as opaque identifiers;
unknown identifiers do not invalidate a reading. Basic visitor access needs no
key, but the page also displays credit pricing and marks some optional fields
as Pro. This is not an unlimited-service promise or a verified live schema.

The [official FAQ](https://uapis.cn/docs/api-reference/faq) currently lists 1,500
monthly visitor credits shared by exit IP and a two-credit weather call, with
nominal visitor limits of four requests per second. Rate/quota headers may
describe the active limits. A rate-limit `429` may provide `Retry-After`;
`VISITOR_MONTHLY_QUOTA_EXHAUSTED` instead means the monthly allowance is exhausted.
Account access uses a bearer key and can return `402`; this preview supports
neither account credentials nor payment. The FAQ describes provider caching as
variable and weather caches as dependent on request IP. KLDE does not assume a
provider cache lifetime or that every request contains newly observed data.
These limits can change or be shared with unrelated clients behind a NAT.

The [fair-use policy](https://uapis.cn/en/docs/getting-started/fair-use-and-rate-limiting)
also describes dynamic limits and recommends caching and exponential backoff.
KLDE's substantially slower schedule is a client policy, not a provider guarantee.

## Bounded asynchronous transport

The adapter uses public Qt Network APIs on the shell's event loop. It has one
in-flight request, a ten-second total deadline plus Qt's transfer timeout, and a
256 KiB response limit. It checks required types instead of coercing missing or
string-valued temperatures to zero. Current temperatures outside the deliberately
broad −150…100 °C validation range are rejected. Unknown optional data is ignored.
The current prototype requests only the fields it can present.

The origin and path are fixed. Redirects are refused, default TLS validation is
retained, and cookies and cached HTTP authentication are disabled for requests.
No response URLs, remote artwork, HTML, scripts or provider-supplied shell actions
are executed. Provider strings must remain plain text in QML. Raw payloads,
location-bearing URLs and private data are not logged. Disabling or destroying
the service cancels its request and scheduled work.

References: [QNetworkRequest](https://doc.qt.io/qt-6/qnetworkrequest.html),
[QNetworkReply](https://doc.qt.io/qt-6/qnetworkreply.html).

## Cache, refresh and failure behavior

- A single current-city/language reading is cached only in memory. Changing the
  configured city clears that reading so a previous city's weather cannot appear
  under the new location. Consent changes cannot bypass the in-process cooldown.
- Successful requests schedule the next update approximately two hours later.
  Manual requests share a fifteen-minute minimum interval and in-flight work is
  deduplicated. No animation or high-frequency polling drives the weather service.
- Transient failures back off by 15, 30, 60 and then 120 minutes. A longer valid
  `Retry-After` delay wins, including HTTP-date values. Long pauses re-arm a bounded
  timer without making an early request. No screen repaint loop is introduced.
- A monthly quota failure stops automatic and manual refresh until the user
  explicitly enables online access again. Schema errors, invalid cities, access
  refusals and redirects do not cause automatic retries.
- A failed real request retains the previous real reading as visibly stale,
  with attribution and an error. With no cached reading the widget shows an
  unavailable state. Failed real requests never silently become mock forecasts.

A two-hour continuous schedule alone costs about 744 credits in a 31-day month
at the documented price. Startup and manual requests add usage; shared-IP quotas
and other applications can still exhaust the allowance. The cadence is chosen to
be conservative, not to guarantee free access. There is no disk cache or monthly
credit estimator yet. Offline DNS/network failures follow the same bounded
backoff and can show the last real reading until disabled or the process exits.

## Attribution, privacy and rights review

The widget identifies real data as weather via `uapis.cn` and labels cached data.
The [provider's full privacy policy and terms](https://uapis.cn/docs/getting-started/privacy-policy)
describe collection of IP and technical access logs, with security logs retained
for at least six months and business logs for 30 days before aggregation/deletion.
They say request parameters and bodies are not persisted by default; KLDE does
not promise anonymity or control the provider's retention practices.

The weather page's personal/commercial-use language must be read alongside the
full terms' restrictions on reselling or redistributing paid services and its
source-attribution requirement. Third-party data rights remain with their
holders. Visitor access does not grant a blanket right to redistribute weather
datasets or relicense observations under KLDE's code/artwork licenses. This
experimental adapter does not establish provider endorsement or resolved data
rights for a future commercial distribution. Maintainers must review current
terms and source-data rights before enabling a shipped service by default or
bundling it into a paid offering. No provider artwork, SDK code or real
observations are copied into the repository.

## Validation and next steps

CircleCI runs deterministic synthetic JSON fixtures and an injected provider and
clock. Tests cover strict parsing, missing optional fields, explicit location,
no requests before consent, deduplication, cache/cooldown behavior, stale data,
monthly quota stops, long provider pauses and cancellation on destruction. They
make no external weather requests and consume no provider quota. Transport
availability, production JSON variants and real account behavior remain
unverified; fixture success must not be reported as a live API check.

Before treating online weather as supported: verify an owner-approved city on a
real connection, review current terms and quota headers, test network changes and
resume, implement settings/consent persistence deliberately, and check localized
unavailable/stale states with assistive technology. Add another provider through
the same interface; do not couple the widget to this endpoint's field names.
