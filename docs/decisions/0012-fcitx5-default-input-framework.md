# 0012 — Fcitx 5 as the initial input framework

## Context

CJK needs mature engines and toolkit compatibility without a new input engine.

## Decision

Use Fcitx 5 with a KLDE indicator/theme and an InputMethodBackend; detect first, real control later.

## Consequences

No new dictionaries/Pinyin engine, no duplicate framework daemon or premature native candidate surface.

## Alternatives considered

A new engine duplicates mature work; maintaining Fcitx and IBus equally now expands scope.

## Future review conditions

Review when real control and compositor-specific candidate protocols are tested.
