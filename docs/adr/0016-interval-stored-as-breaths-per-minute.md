---
id: 0016
title: The pace is stored as hundredths of a breath per minute
status: superseded
superseded-by: 0017
---

## Context

The setting a wearer thinks about is a breathing rate, so the app stored one and
the screen translated it into an interval for the timer.

## Decision

Store `paceHundredths`, hundredths of a breath per minute. The screen showed
both the rate and, in parentheses, the interval it worked out to.

## Consequences

Two problems, and the second is what ended it:

- The combined line was wide enough to draw over both control circles
  (ADR-0013).
- **The stored number was not the number the timer ran.** Every read went
  through a division, and the row showed a value the wearer could not check
  against a clock by counting one gap between buzzes.

Superseded by ADR-0017. The key survives and is still migrated — see ADR-0025 —
and its conversion is the same function the PACE row uses today (ADR-0019).
