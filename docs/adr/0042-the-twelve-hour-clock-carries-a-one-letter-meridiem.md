---
id: 0042
title: The 12-hour clock carries a one-letter meridiem
status: superseded
superseded-by: 0043
---

## Context

`ClockText.formatTime` rendered 12-hour times with no meridiem at all: 16:12
drew as `4:12`, indistinguishable from 04:12. On a watch whose owner has set a
12-hour display — which is most of the United States — the main screen showed an
ambiguous time all day.

Noon and midnight are the sharp end of it. `hour % 12` is 0 for both, so they
render identically, twelve hours apart, with nothing on the glass to separate
them.

## Decision

12-hour times get a **one-letter** suffix: `4:12p`, `12:00a`.

Not "AM"/"PM", and that is forced rather than chosen. The clock is drawn in the
top slot at `FONT_MEDIUM` — the largest font on either screen, nearest the top
edge, where the round chord is at its tightest. Measured there, the budget is
**166 px** and every full form overruns it:

| string | width |
| --- | ---: |
| `12:48` (before) | 111 px |
| `12:48a` | 135 px |
| `12:48 A` | 151 px |
| `12:48pm` | 175 px |
| `12:48PM` | 178 px |
| `12:48 PM` | 189 px |
| `10:08 PM` | 189 px |

Dropping the clock to `FONT_XTINY` would fit `PM` comfortably (206 px of budget,
115 px of string) and was rejected: that is the size of the setting captions, and
the clock would lose the hierarchy that makes it glanceable. A smaller second
font drawn beside the time was rejected too — every other line on both screens is
one centred string, and the exception costs more than the letter saves.

Lower case, because the screen's other words are upper-case captions (`EVERY`,
`POWER`, `BUZZ`, `BPM`) and a capital `P` beside the clock would read as one of
them rather than as part of the time.

The suffix keys off the **raw** hour, never the wrapped one.

## Consequences

12-hour strings are one character longer than before and no longer end in a
digit. `clockTextFormatsEveryMinuteOfTheDay` asserts both, and the colon's
position is now format-dependent — third-from-last in 24-hour, fourth-from-last
in 12-hour.

`clockTextSeparatesNoonFromMidnight` exists specifically because that pair is
the one case with no visible symptom in the digits: derive the meridiem from
`hour % 12` and one of them is silently wrong.

`layoutEveryClockMinuteFits` already swept all 1440 minutes in both formats, so
the widened strings were measured against the chord the moment they existed
rather than needing a new test.

24-hour output is untouched.
