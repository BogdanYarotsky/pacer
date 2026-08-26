---
id: 0022
title: The interval range, and why its floor was finally chosen
status: accepted
---

## Context

Under ADR-0017 the floor was the platform's `Timer` minimum — technical,
inherited, never argued. The ceiling was a design choice: comfortably past any
breathing practice.

## Decision

Two things set the floor when the PACE row arrived, and it was chosen for the
first time:

- **A pace tap must always move the stored interval.** The rungs narrow as the
  square of the rate, so a fine pace step (ADR-0020) puts a hard ceiling on the
  rate — past it a control would silently do nothing.
- **Nobody paces breathing above that ceiling anyway.** The documented resonance
  bands are 4.5–7.0 breaths/min for adults and 6.5–9.5 for children
  (Lehrer/Vaschillo). Above roughly ten is ordinary resting respiration, which
  wants no metronome.

The interval floor is then the reciprocal image of the pace ceiling, exactly —
not a separate decision (ADR-0019).

## Consequences

What it costs is the sub-floor haptic metronome, which was a side effect of the
`Timer` minimum and not a capability anyone asked for.

A watch holding an interval below the new floor falls back to the default on the
next launch, because stored values are range-checked before they are trusted
(ADR-0025). The band affected is below any breathing practice.

The ranges themselves live in `candleApp` and their coherence is asserted, not
restated here — ADR-0033.
