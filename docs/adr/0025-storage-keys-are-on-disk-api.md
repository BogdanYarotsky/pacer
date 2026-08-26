---
id: 0025
title: Storage keys are on-disk API; a unit change is a new key
status: accepted
---

## Context

`Application.Storage` keys live on watches this repo cannot reach.

## Decision

**Renaming a key silently resets that setting on every installed watch.** And
**changing a key's UNIT is not a rename — it is a new key plus a migration.**
Never reuse a key for a new meaning.

## Consequences

The interval has been through this twice (ADR-0016 → ADR-0017 → ADR-0018), and
both legacy keys are still read. The migration walks the chain newest-first and
converts at most once, deleting each legacy key as it is consumed so a
conversion cannot run twice and overwrite a later adjustment.

The two legacy links differ, and the difference is the point:

- The hundredths key converts by a clean factor and its **whole** old range is
  valid, so there is no plausibility window — any number that build could write
  is a real interval. It is clamped, because the old range reached below today's
  floor (ADR-0022), and a wearer parked below it gets the floor rather than the
  default: the nearer of the two to what they had.
- The bpm key **does** need a plausibility window. That build could only write a
  narrow band, so anything outside it is not a pace and is left where it lies
  rather than converted into nonsense.

`Storage.getValue` returns a wide poly type, so every read is checked for being
a Number **and** for being in range before it is trusted. Anything else falls
back to the default rather than propagating a bad value into the timer.

The migration is observable nowhere but through Storage, which is why one of the
four Storage-writing tests exists for it.
