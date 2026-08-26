---
id: 0006
title: The clock stays, and it gates the only periodic redraw
status: accepted
---

## Context

Deleting the clock has been proposed once, on the argument that it does no job
the app needs and costs a repaint a minute for nothing.

## Decision

It stays. Reading the time without breaking off a breathing session *is* the
job, and one repaint a minute is what it costs.

`timerCallback` requests an update **only when the displayed minute changes**,
so a session repaints about once a minute rather than once per cue.

## Consequences

The battery rides that same repaint for free: it is read inside `onUpdate`, so
it refreshes when the minute does, is at most a minute stale, and asks for no
repaint of its own. Every other change requests its own update.

The gating is also why the cue timer carries the clock instead of a second timer
beside it. A free-running 60 s timer would drift up to a full minute behind the
wall clock; hanging the check on the cue keeps the displayed minute at most one
cue interval stale, for no extra timer at all. The device allows three timers
and the app uses all three (cue, hold-to-repeat, exit hint).

`onActive` redraws too — the clock can be a whole minute stale by the time the
app returns to the foreground.
