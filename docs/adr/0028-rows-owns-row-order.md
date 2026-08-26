---
id: 0028
title: Rows owns which settings are on which screen, in what order
status: accepted
---

## Context

The row order used to live in two places that had to agree by hand: the hit
encoding, and the draw calls in the view. When they disagreed **everything still
compiled, every test still passed, and every tap silently edited a different
setting than the one under the thumb.**

## Decision

One list per screen, in `Rows.forScreen`. The view draws that list and the
delegate maps taps through the same list, in the same order — they cannot
disagree, because they are reading the same array.

A row identity is *not* a position. A row's position is its index in that list,
and nothing outside the list may assume one (ADR-0014).

## Consequences

Swapping two names in that one function moves the rows on the glass and moves
every tap with them, in the same edit. Which rows sit where is a design decision
and this is the only place it is made.

**A setting reachable from no screen is still a live setting** — drop it from
every list and it keeps its stored value, keeps driving the cue, and has nothing
on any screen to change it by. That is the guarded failure.

The guard asserts "at least once", not "exactly once", because ADR-0019 puts two
rows on one setting deliberately. What the weakening costs is a second check: a
row naming an identity nothing answers to would draw a caption, take taps and
edit nothing.

Callers resolve the list once and hold it; it never changes while a screen is
alive.
