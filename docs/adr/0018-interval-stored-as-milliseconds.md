---
id: 0018
title: The interval is stored in milliseconds
status: accepted
supersedes: 0017
---

## Context

ADR-0020 set the PACE row's step at the precision the measuring tools report.
Hundredths of a second **cannot represent it**: across the pace range a quarter
of the rungs collide with their neighbour, the first collision landing inside
the resonance band itself. Those would be taps that change the number on the
glass and nothing underneath it.

## Decision

Store milliseconds. Every pace rung then maps to a distinct interval with margin
to spare, and milliseconds are what the cue timer takes anyway — so the stored
number is now the number that runs.

## Consequences

`CandleMath.intervalMillis` is gone. It converted hundredths to milliseconds and
would be the identity today.

The EVERY row still *reads* at hundredths of a second, so an interval the PACE
row put between two hundredths is **rounded for display** while the exact value
stays underneath. Three decimals would be honest and would also make it the
widest line on the screen (ADR-0013) to report a millisecond nobody is pacing to.

Third stored unit for one setting, so the migration chain is now two links long
(ADR-0025). A watch that has run any build of this app keeps its measured
frequency.

The collision counts and margins above are computed by
`settingsPaceAndEveryAreOneSettingTwoViews`, which walks every rung and every
interval rather than sampling. Per ADR-0033 they are not written down here.
