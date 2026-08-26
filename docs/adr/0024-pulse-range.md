---
id: 0024
title: The PULSE range starts below perception and stops short of a buzz
status: accepted
---

## Context

`VibeProfile.length` is documented only as "milliseconds" — the SDK states no
bounds at either end, so this range is entirely our own choice.

## Decision

The floor is deliberately below anything a body can register, for the same
reason as ADR-0023's: a range that starts at the threshold cannot tell you where
the threshold is.

The ceiling came down substantially from the first version. The top three
quarters of that range were reaching for nothing.

## Consequences

Published vibrotactile work puts the shortest perceivable pulse around 30 ms and
rhythmic patterns nearer 50 ms; actuator rise time is the harder limit, 50–100 ms
to reach full amplitude on a rotating-mass motor. **Expect the first genuinely
felt step to be some way above the floor.**

A pulse long enough to be felt as a buzz rather than a tick has stopped being a
metronome beat, which is what the ceiling is protecting.

Lowering the ceiling also made the scale walkable in a couple of dozen taps
instead of a hundred.
