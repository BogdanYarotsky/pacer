---
id: 0021
title: EVERY taps snap to the ladder rather than adding to the value
status: accepted
---

## Context

Adding a step to the current value is only sound while the current value is on
the ladder, and the PACE row guarantees it is not (ADR-0019). From an
off-ladder interval a plain addition walks parallel to the ladder and never
touches a round tenth of a second again.

The wearer's own words: *"I can't make it EVERY 5.1s without guessing a proper
PACE before that."*

## Decision

`CandleMath.everyUp` / `everyDown` snap to the rung on the tap's own side of the
current value. Integer division does the snapping. From then on the value is on
the ladder and the steps are plain again.

## Consequences

The ladder is anchored at zero rather than at the range floor, which is what
keeps both endpoints on it.

Steps at the range ends deliberately land **outside** the range; the setter's
clamp brings them back. That is what keeps an endpoint reachable from an
off-ladder value, and it is the same division of labour ADR-0026 describes.

Exactly the shape `strengthUp`/`strengthDown` already had (ADR-0023) — the
pattern was in the codebase before this row needed it.

The two steps now do different jobs on purpose: PACE is the precision
instrument, EVERY the coarse one.
