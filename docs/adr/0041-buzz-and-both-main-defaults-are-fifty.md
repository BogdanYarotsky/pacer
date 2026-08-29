---
id: 0041
title: The row is BUZZ, and both main-screen settings default to 50
status: accepted
---

## Context

The main screen's second row was `PULSE`. The word describes the waveform, not
the sensation: what reaches a wrist is a short buzz, and that is the word a
wearer would use for it unprompted.

Its default was 100 ms against `POWER`'s 20%, which are two tuned-looking
numbers with no relationship to each other.

## Decision

**`BUZZ`**, and **both main-screen settings start at 50** — `POWER 50%` and
`BUZZ 50ms`.

The matching numbers are a statement about the screen rather than about the cue.
Two rows reading the same value say *these are yours to move* more plainly than
a tuned-looking pair does; neither number is a recommendation, which is the same
principle ADR-0022 states for the interval.

The rename is display-and-identity only. `Rows.PULSE` became `Rows.BUZZ` and
`Display.LABEL_PULSE` became `LABEL_BUZZ`, but the storage keys
(`vibrationStrength`, `vibrationDuration`) are untouched — they are on-disk API
(ADR-0025) and name the setting, not the caption. **No migration is needed and
none was written**; a watch upgrading from any earlier build keeps its values.

## Consequences

The default cue changes character: stronger and half as long as before. Those
pull in opposite directions and the outcome is **not predictable from here** —
the README's own hardware notes put actuator rise time at 50–100 ms to full
amplitude, so a 50 ms pulse may never reach the amplitude `POWER 50%` asks for.
It is entirely possible the new default feels *weaker* than the old one despite
more than doubling the strength. Only a wrist can say (ADR-0027), and this is
worth checking deliberately rather than assuming.

`BUZZ` is also four characters where `PULSE` was five, so every line on that row
got narrower. Nothing depended on it being the widest — the hit-zone test
measures the real strings rather than naming a winner — but a comment in
`LayoutTest` that named `PULSE` as the widest row was updated with it.

The word now clashes slightly with the range rationale in the README, which used
"buzz" for the *long* end of the scale — a pulse long enough to feel like a buzz
rather than a tick. That sentence was reworded; the row's name should not be a
pejorative twelve lines further down its own documentation.

Screenshots for the store listing must be retaken: every existing one shows
`PULSE 100ms` and `POWER 20%`.
