---
id: 0043
title: The clock drops one font size and keeps a full AM/PM
status: accepted
supersedes: 0042
---

## Context

ADR-0042 gave the 12-hour clock a one-letter meridiem — `4:12p` — on the
measured grounds that `12:48 PM` is 189 px against a 166 px budget at the top
slot's tightest point, and that every full form clips.

Every one of those numbers was correct, and the conclusion was still wrong,
because the measurement stopped at the wrong variable. It treated the clock's
font as fixed and asked what suffix fits inside it. The question worth asking
was which font makes the suffix fit.

Bogdan pushed back on the result — *"I don't believe 12:48PM won't fit"* — which
was the right instinct about a 390 px screen rejecting a 189 px string.

## Decision

The clock is **`FONT_SMALL`**, and the 12-hour suffix is the full **` AM`** /
**` PM`**.

One size down costs 6 px of glyph height and buys 12 px of chord, because a
shorter box starts lower on a round screen where the glass is wider:

| clock font | height | box top | budget | `12:48 PM` |
| --- | ---: | ---: | ---: | --- |
| `FONT_MEDIUM` | 54 | y=19 | 166 px | 189 px — clips |
| **`FONT_SMALL`** | **48** | **y=22** | **178 px** | **168 px — fits** |
| `FONT_TINY` | 41 | y=26 | 194 px | 143 px |

`FONT_SMALL` is the largest font that fits the string, and it is still half
again the height of `FONT_TEXT` (32 px), so the clock keeps the hierarchy that
makes it glanceable. Going further down to `TINY` buys margin nobody needs at
the cost of the thing being legible at a glance.

The suffix keys off the **raw** hour, never the wrapped one — `hour % 12` is 0
for both noon and midnight.

## Consequences

**A test was measuring a font the view no longer used.** `LayoutTest` named
`Graphics.FONT_MEDIUM` in two places, so both clock sweeps would have gone on
proving that strings nobody draws still fit. They now read `FONT_CLOCK` off the
view through `clockFontFromTheView()`, which is the only place the coupling
lives. That is the class of bug this repo keeps finding in prose; it was in a
test this time.

The clock is 6 px shorter on the main screen. That is the entire visual cost,
and it is far smaller than the ambiguity it removes — a 12-hour watch was
showing `4:12` for both halves of the day (ADR-0042's context still holds).

`layoutEveryClockMinuteFits` needed no edit beyond the font source: it already
swept all 1440 minutes in both formats, so the widened strings were measured
against the chord the moment they existed.

**Lesson worth keeping:** a measurement that answers the question you asked can
still be the wrong measurement. "Does this string fit this font?" and "what font
does this string need?" have different answers, and only one of them was worth
having.
