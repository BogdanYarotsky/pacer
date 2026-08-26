---
id: 0007
title: The measured input event chain -- do not re-derive it
status: accepted
---

## Context

A behaviour event on its own cannot tell a physical button from a touch. This
chain was measured on a vívoactive 5 by driving real input into the simulator
(`tools/input.ps1`), not inferred.

## Decision

Treat this table as fact:

```
tap          -> onSelect, then onTap        (onSelect fires FIRST)
press enter  -> onKeyPressed(4), onSelect, onKey(4), onKeyReleased(4)
press esc    -> onKeyPressed(5), onBack, onKeyReleased(5)
hold  menu   -> onKeyPressed(5), onMenu, onKey(7), onKeyReleased(5)
swipe right  -> onBack           <-- no onSwipe in the simulator
swipe left   -> onSwipe(3) only, no behaviour event
swipe up     -> onNextPage, onSwipe(0)
swipe down   -> onPreviousPage, onSwipe(2)
touch hold   -> onHold at the threshold, onRelease at lift, and NEITHER
                onSelect nor onTap -- tap and hold are disjoint by
                measurement, not by hope
```

## Consequences

Two things earlier versions of this file got wrong:

- **Consuming `onTap` cannot suppress a tap**, because `onSelect` is dispatched
  first.
- `onSelect` must **decline** so the later coordinate-bearing `onTap` runs.
  Returning true suppresses it on this device, and `onSelect` has no
  coordinates to edit a control with.

The simulator lies about the right swipe specifically — see ADR-0008.
`tests/input-behaviour.ps1` re-asserts this chain against real input, which is
why the trace lines in the delegate are not decoration.
