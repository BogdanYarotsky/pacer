---
id: 0005
title: What earns a place in the main screen's bottom slot
status: accepted
---

## Context

The main screen has one line along the bottom, and everything wants to live
there.

## Decision

It holds, in strict precedence: the `HOLD TO EXIT` hint for two seconds after a
Back, then a `VIBE OFF` warning, then the battery charge. Nothing shares the
line — the warning takes it outright.

**The bar: it must be a fact about the session in front of you, and it must not
change between two cues at fixed settings.** That second half is ADR-0001's
test. A cumulative session dose would fail it; a rate computed from the settings
would pass.

## Consequences

Three things have been evicted, and the list is the useful part:

- **The build version**, moved to the settings screen (ADR-0032). A fact about
  the install, not the session.
- **The Candle mark**, a bitmap release builds drew here. It passed ADR-0001 on
  a technicality — static, drawn identically every frame — but the screen you
  breathe on is not a place to advertise.
- **A vibration-exposure readout**, weighed and declined: the watch cannot
  measure its own motor, and a cumulative dose would fail the test above anyway.

`VIBE OFF` is the app's single visible failure mode — a watch with vibration off
runs a flawless session and delivers nothing, which is indistinguishable from a
dead motor or a bad sideload. A future agent will read ADR-0001 and want to
delete it. Do not.

The strings must not share a line, and a test measures that rather than a
comment asserting it.
