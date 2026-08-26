---
id: 0027
title: The VibeProfile is cached and invalidated by the two vibe setters
status: accepted
---

## Context

The cue fires many times a minute for the length of a session, and the profile
it hands the motor is rebuilt from two numbers that rarely change.

## Decision

Build it once, cache it, and invalidate on a strength or length change.

## Consequences

If invalidation ever stopped, **the screen would show a new value while the
wrist kept feeling the old one** — a divergence nothing else in the app could
see, because `Attention.vibrate` does nothing observable in the simulator.

That is why a test reads the profile the wrist would actually feel, rather than
the two numbers it was built from. Those numbers are covered everywhere; the
cache between them and the motor is not, and the test was written after both the
invalidation and the timer restart were deleted in turn to check it caught them.

A pace change restarts the cue timer; a strength or length change does not. So a
strength tap lands on the next cue — up to a full interval later — and will not
alter a buzz already in flight. Both behaviours are deliberate and only
verifiable on a wrist.
