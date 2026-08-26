---
id: 0023
title: POWER walks a two-zone ladder
status: accepted
---

## Context

The strength scale has to be walkable end to end in a couple of dozen taps, and
also has to be able to find the hardware's real threshold — which is not
knowable from here. A rotating-mass actuator has a minimum duty cycle below
which it does not turn at all, and where that sits on this watch is a question
only a wrist can answer.

## Decision

Coarse steps over the working range, single-percent steps at the bottom. The
floor is the weakest cue the API can express, not silence.

## Consequences

**The floor is above zero deliberately.** The bottom of the scale should be the
weakest cue the hardware can *attempt*; there is no mute branch anywhere in the
cue path, and nothing may quietly reintroduce one.

The fine zone exists so the scale does not step *over* the threshold it is meant
to help find.

Integer division snaps an off-ladder value in the tap's own direction — the same
mechanism as ADR-0021. This matters because earlier builds shipped different
ladders, so an installed watch can hold values today's taps would never write.

The zones must meet with no gap in either direction, and the ceiling and default
must sit on coarse rungs. All of that is asserted rather than described.
