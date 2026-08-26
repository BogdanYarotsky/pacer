---
id: 0014
title: The centre of a row is inert; only the edges take taps
status: accepted
---

## Context

Reading a value must never change it.

## Decision

Only the large edge zones map to a row and a direction.
`Layout.CONTROL_HIT_EDGE` stops short of where the widest row line begins, and
the hit map encodes **(row * 2) + direction** — a *position* on the screen and
which side of it was touched, and deliberately nothing about which setting is
standing there.

## Consequences

The encoding carrying position and nothing else is the whole difference from the
`ACTION_` constants it replaced. Those named the settings, so the encoding
itself asserted which setting was in which row — true on the only screen there
was, and false the moment a second screen existed, where position 0 is a
different setting on each.

`Rows.forScreen` is the only thing that knows which setting is where, and both
the view and the delegate read it (ADR-0028), so a re-ordered screen cannot
leave a tap pointing at the wrong setting.

The hit edge is derived from a measurement of the widest reachable line, and its
guardrail's failure message states how far back it must move. That is how the
number was picked every time it has moved — never by choosing it.

The settings screen's `BACK` band (ADR-0010) is asked as a **separate question**,
not folded into this encoding: `BACK` is not a row, and putting a non-position
into an encoding whose point is position would give the whole thing away.
