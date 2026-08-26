---
id: 0008
title: The firmware synthesizes a real KEY_ESC for a right swipe
status: accepted
---

## Context

The app was closing itself mid-session. `MainInputGate` was built on the premise
that touch gestures never raise key events, so `onBack` could tell the physical
lower button from a right swipe by asking whether a `KEY_ESC` had been latched.

A Storage-persisted breadcrumb of the last input events answered it on the
wrist: **six reproductions, every chain ending `P5>B!`, from swipes with no
button press.** The `B!` tag was only reachable when
`MainInputGate.consume(KEY_ESC)` returned true, and the only thing that latches
that gate is `onKeyPressed(KEY_ESC)`.

## Decision

Accept that **`onBack` cannot tell a thumb from a sleeve on this hardware**, and
stop asking it to. See ADR-0009 and ADR-0010 for what replaced it.

## Consequences

- `MainInputGate`'s premise is false for `KEY_ESC` and **true for `KEY_ENTER`** —
  a tap raises `onSelect` with no key — which is why the upper button can still
  be told from a tap.
- The wrist **does** raise `onSwipe(SWIPE_RIGHT)`; the simulator never does.
  Second time the simulator has misled us about this exact gesture.
- **Touch evidence preceded the forged key in only two of six.** So there is no
  companion event to gate on either — a "was there a recent drag?" check would
  have failed open two times in three.
- The breadcrumb instrument was deleted once it had answered this. Do not go
  looking for it; rebuild it deliberately if a new exit bug appears.
- **Do not re-derive any of this**, and do not reach for `configureTouchEvents`
  (ADR-0004).
