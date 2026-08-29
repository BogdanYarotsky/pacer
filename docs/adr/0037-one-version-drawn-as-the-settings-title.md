---
id: 0037
title: One version number, drawn in every build as the settings screen's title
status: accepted
supersedes: 0032
---

## Context

ADR-0032 drew the version in **debug builds only**, on the reasoning that it was
a developer's instrument — the only proof a sideload landed (ADR-0034) — and
that drawing it for a wearer duplicated what the Connect IQ phone app already
reports, which ADR-0003 rejects everywhere else.

Two things changed. The store submission made a second reader real: someone
writing a bug report has the watch in their hand and the phone app three taps
away on a different device. And ADR-0036 emptied the settings screen's bottom
band, which left that screen with nothing drawn on it at all in a release build.

A first attempt at serving both readers used two numbers — a hand-set release
version plus an auto-bumped build counter, drawn as `v1.0.31` in debug and
`v1.0` in release. It was rejected on sight: three parts looked ugly *because*
it was two numbers pretending to be one, and it would have needed a
build-to-release map maintained by hand, which is the drift this repo keeps
legislating against.

## Decision

**One number, `APP_VERSION`, drawn in every build**, as the settings screen's
title: `Candle v1.0`.

**One digit each side of the dot**, always. The minor is the sideload counter
`deploy.ps1` already bumps, and it **rolls**: `1.9` is followed by `2.0`.

This is deliberately **not** semantic versioning. The major carries nothing
about compatibility — it is the tens digit of a plain odometer. The rule is
written for the person reading the number out loud, not for a dependency
resolver: every version this app can ever show is four characters, and `1.10`
and `1.30` are exactly the strings it exists to prevent.

It has a second effect worth naming, because it was the reason the rule got
tightened: a version that can grow makes the layout budget size itself for
strings nobody will ever ship, which means a smaller font for the realistic
case. A closed domain of a hundred strings can simply be swept.

`9.9` is the end of the odometer and `deploy.ps1` **fails** there rather than
rolling to `10.0`, which would break both the rule and the width budget
silently. What comes after is a decision for a person.

Whatever it says on submission day is what gets typed into the store form. The
manifest carries no app-version field — the store version is a typed string —
so the glass, the listing and the phone app can be made to agree by construction.

`Display.buildLine` and its annotated `showsBuildVersion` predicate are gone.
There is no `(:debug)`/`(:release)` pair here any more, and therefore no way for
a release build to draw a string the tests never measured.

## Consequences

Store versions **skip**: ship 1.0, iterate privately, ship 1.7. That is the
whole cost, and it buys a number that names an exact commit when a wearer reads
it out. The tidy alternative names a range.

ADR-0032's standing hazard is retired with it — that the verification loop would
die silently if a release flag ever reached the deploy path, because the version
would simply stop being drawn. It is drawn unconditionally now, so that failure
mode no longer exists.

The name is in the string because this is a **title**, not because the app needs
identifying to its own wearer. Room was never the question — the settings
screen's top band is the narrowest the app draws text in, and the title clears
it with the counter run well past anything it will reach. The margin is a
measurement and lives in `layoutRealLinesFitOnVivoactive5`, not here.

A Store install's settings screen is no longer blank: the title is at the top,
and the bottom band stays the exit hint's (ADR-0036).
