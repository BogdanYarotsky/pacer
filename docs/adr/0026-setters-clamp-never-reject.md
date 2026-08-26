---
id: 0026
title: Setters clamp rather than reject
status: accepted
---

## Context

A step that walks off the end of a range has to do *something*, and a stored
value need not be on today's ladder — earlier builds shipped different ones.

## Decision

Clamp into the range. Every step arm is deliberately **unclamped**: each setter
clamps, so a step off the end is the no-op it should be and the endpoint stays
reachable from a value that is off the ladder.

## Consequences

Rejecting instead would leave a control dead one step short of an endpoint with
nothing on screen to explain why.

The clamping is what makes the **unchanged guard** necessary: without it, every
tap on `+` at the maximum would rewrite Storage and restart the cue timer to no
effect.

At a range end a hold parked on the endpoint costs a few empty calls a second
and changes nothing; the repeat timer still stops at release like any other.

Because the clamp is what recovers the endpoint, the range walk that proves it
deliberately **starts off the ladder** — a walk that starts on it never needs
the clamp at all and would prove nothing.
