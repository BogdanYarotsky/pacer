---
id: 0038
title: The BPM row draws no caption; its unit is its caption
status: accepted
---

## Context

The settings screen's second row read `PACE 5.88bpm` — a label, a number, and a
unit, saying the same thing twice. "PACE" is this project's word, not the
wearer's: the tools that measure a resonance frequency (Yudemon, Elite HRV)
report *breaths per minute*, and that is the word someone arrives holding.

ADR-0019 made `EVERY` and this row two views of one setting, which is what makes
the label removable. The row is not a control a wearer has to find; it is a
readout that follows the row above it.

## Decision

The row draws **`5.88 BPM`** and no caption. The unit does both jobs — it is the
reading and the row's name.

`Display.rowLabel(PACE)` still returns `"PACE"`. The label is the row's **name**,
which the delegate's traces and `tests/input-behaviour.ps1` identify it by; only
three of the four rows also draw theirs. `Display.rowText` is the one place that
distinction lives.

## Consequences

The screen teaches itself in one direction and not the other, deliberately.
Someone who knows what a resonance frequency is needs no caption. Someone who
does not is meant to work the `EVERY` row above and watch this one move on its
own — which demonstrates the coupling far better than a word for it would.

The unit is spaced off the number and set in capitals so it reads as the row's
caption rather than as a suffix, matching `EVERY`, `PULSE` and `POWER`.

It is also the shortest this row has ever been, which matters because it shares
a width budget with three-digit values at both ends of the range (ADR-0013).
The sweep in `layoutEveryReachableValueFits` composes the line through
`Display.rowText` rather than spelling it, so the budget is measured against
what is actually drawn (ADR-0029).
