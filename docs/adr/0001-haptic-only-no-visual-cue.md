---
id: 0001
title: The cue is haptic. There is never a visual breathing indicator.
status: accepted
---

## Context

The app exists to pace breathing *without* looking at the watch.

## Decision

No animated arc, no pulsing ring, no phase readout. A screen that does not
change between pulses is the intended design, not a gap.

## Consequences

A reviewer will read this app as unfinished and want to add a breathing
animation. **Do not.** A visual cue would invite exactly the attention the app
is built to free.

The main screen carries three things that change on their own — the clock, the
battery and a `VIBE OFF` warning — and none of them is an exception. See
ADR-0005 for the bar anything on that line has to clear.
