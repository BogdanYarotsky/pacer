---
id: 0030
title: Layout and CandleMath touch nothing -- so everything is testable
status: accepted
---

## Context

The alternative to testable geometry and arithmetic is looking at screenshots,
which sees only what someone thought to look at.

## Decision

`Layout` takes screen dimensions and font metrics as arguments and returns
coordinates or a fit answer; it never touches a `Dc`. `CandleMath` is cue
arithmetic and formatting with no application instance behind it.

Both therefore run under the unit test runner without drawing anything, which
makes `shots/*.png` the last resort rather than the main loop.

## Consequences

Arithmetic can be swept **exhaustively** without writing a single value to
Storage — and it is: every reachable value of every row, every rung of every
ladder, every minute of the clock.

Tests that used to drive the real setters could strand a value in the
simulator's persisted state when a run was killed. That happened. Only four
tests write to Storage now, each because its subject is observable nowhere else,
and each restores from a `finally` rather than from the end of the happy path —
an assertion throws, and a restore that only runs on success strands whatever
value the test died on for every run after it.

`Layout` models this well and `candleApp` does not: constants there carry their
consequences in prose where Layout computes from arguments. Constants that
derive from each other should derive in code — the interval floor **is** the
pace ceiling's reciprocal, and a test asserts that rather than the code
expressing it. Unfinished business.
