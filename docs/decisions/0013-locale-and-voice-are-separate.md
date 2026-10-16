# 0013 — Locale and voice are separate

## Context

Personality should not corrupt standards-based language/region settings.

## Decision

Store locale en/zh_CN separately from standard/cute voice with stable resource IDs and base fallback.

## Consequences

No fake glibc locales; untranslated Cute entries use Standard; preferences remain session-only initially.

## Alternatives considered

Separate fake locales duplicate catalogs and break system assumptions; literal-only strings are fragile.

## Future review conditions

Review persistence/schema migration and additional locales before shipping settings.
