---
id: 0013
title: The second width budget -- a row's text must clear its controls
status: accepted
---

## Context

An editor row has a circle parked at each end and its text centred between them.
**A line that fits the chord can still be drawn straight through both
controls**, and the chord check cannot see it: rows sit near the vertical centre
where the glass is widest and that check is at its most forgiving.

Not hypothetical. `"5.22 sec (5.75 bpm)"` cleared every fit check on the screen
while sitting on top of both circles.

## Decision

`Layout.editorTextMaxWidth` is that second budget — the gap between the controls
less a gutter each side — and every reachable value of every row on every screen
is measured against **both** budgets.

## Consequences

That incident is why the interval row says `s` and not `sec`, and why it carries
no second number in parentheses. It is also the argument that survived the
arrival of the PACE row (ADR-0019): the same information now occupies two rows
at a fraction of the width apiece, rather than one line wide enough to overdraw
the controls.

The gutter exists so a line that only just misses the circles does not read as
if it touches them.

**No string drawn on a row is free to lengthen.** Adding a character to a
caption or a unit is a layout change, and the sweep is what says so.
