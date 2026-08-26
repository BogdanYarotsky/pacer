---
id: 0020
title: PACE steps at the precision the measuring tools report
status: accepted
---

## Context

An assessment hands you a number. If the row cannot land on it exactly, the
wearer is back to rounding and "close enough" — which is the friction ADR-0019
exists to remove.

## Decision

The PACE step is the precision Yudemon reports. It is far finer than the
clinical protocols, which walk the assessment range in much coarser steps, so
any measured frequency lands exactly on a rung with room to interpolate.

## Consequences

**This is about faithful entry, not about perception.** One rung is a few
milliseconds of cue interval in the resonance band; no wrist can tell two
adjacent rungs apart. The value is that the number you were given is the number
in the watch.

It forced the stored unit to milliseconds — see ADR-0018 — which is the real
cost and was not visible when the step was chosen.

It also costs a long hold to cross the whole range at the repeat rate. Crossing
it is not a thing anyone does: you arrive near your own frequency and nudge. If
it ever grates, a two-zone ladder like ADR-0023's is the shape to reach for.

The rungs narrow as the square of the rate, so a step this fine bounds the
range's ceiling — see ADR-0022.
