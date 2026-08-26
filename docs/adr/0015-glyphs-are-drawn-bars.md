---
id: 0015
title: The "-" and "+" are drawn bars, not font glyphs
status: accepted
---

## Context

The two controls sit either side of one row and are meant to read as one control
twice. Set in a font they did not: the hyphen's ink was **half** the plus's
width, and both sat low.

Neither fault was catchable by a test. `getTextWidthInPixels` reports an
**advance** width, so the two strings measure alike while the ink does not; and
`TEXT_JUSTIFY_VCENTER` centres the font's *line box*, never the ink. Both were
found by counting white pixels in a screenshot, which was the only instrument
that could see them.

## Decision

Draw both as filled rectangles from Layout constants. The plus is the minus with
its two extents swapped, so one function defines "centred" and the widths cannot
diverge.

## Consequences

**Both extents must be ODD.** A bar of even thickness has its centre on a pixel
boundary and must land half a pixel off the circle's centre whichever way the
division rounds; an odd one has a middle pixel to put there. A test asserts the
parity, the centring, that the glyph clears the ring's inner edge, and that it
is not a speck inside the circle.

The view takes the same `increase` boolean the hit encoding and the setter take,
so the glyph a control wears and what a tap on it does are one fact spelled one
way. A glyph string would have been a second spelling.

There is no third font in the view: the clock, and everything else.
