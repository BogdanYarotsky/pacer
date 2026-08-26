---
id: 0019
title: EVERY and PACE are one setting on two rows
status: accepted
---

## Context

The tools that measure a resonance frequency (Yudemon, Elite HRV, the
Lehrer/Vaschillo assessment) report **breaths per minute**. The timer runs
**seconds between cues**. The conversion is a reciprocal, and the app was asking
a wearer to do it on a wrist.

## Decision

Two rows, one setting. `EVERY` is seconds between cues, `PACE` is breaths per
minute, nothing is stored for `PACE`, and a tap on either ends in the interval
setter. Type in whichever number you were handed.

This is the one place the "a row is one setting" rule (ADR-0028) bends, and it
bends deliberately.

## Consequences

Three things read as bugs and are not:

- **Their `+` controls move the stored interval in opposite directions.** More
  breaths per minute is a shorter interval. Reciprocal units cannot agree on
  which way is up, and a bpm row whose `+` lowered the bpm would be worse.
- **`PACE` steps from the value on the GLASS, not from Storage.** Its displayed
  value is rounded to the nearest rung, and the tap moves from that rung. This
  is what makes `+` then `-` return. Stepping from the raw stored interval would
  break reversibility the moment an EVERY tap left it between rungs — which it
  does constantly, since the two ladders line up at exactly one rate.
- **The row you last touched is exact; the other is a readout.** Dial `PACE` to
  a tool's number and `EVERY` will read something off its own ladder. That is
  correct. Never snap the other row to make it look tidy.

The two ranges must be **exact reciprocal images** of each other or one row
acquires a state its controls cannot leave. `settingsRangesAndStepsAreCoherent`
pins that relationship rather than the constants, so the range stays free to be
re-argued as long as both halves are re-argued together.
