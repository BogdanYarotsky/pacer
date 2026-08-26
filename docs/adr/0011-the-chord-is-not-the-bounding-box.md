---
id: 0011
title: On a round screen the chord is not the bounding box
status: accepted
---

## Context

The vívoactive 5 is a ROUND display (SDK device config, deviceFamily
`round-390x390`). Usable width shrinks toward the top and bottom edges.

## Decision

Fitting the bounding box is not fitting the screen. `Layout.halfChordAt` models
the real chord, and every line the app draws is measured against it at its own
anchor, on both screens, using the device's own font metrics.

## Consequences

This is the reason the layout tests are worth having at all. It also means a
value measured at the main screen's row 0 says nothing about the same value on
the settings screen — a row's anchor depends on how many rows share its screen,
so every sweep walks both.

Both edges of a glyph box are checked, because whichever sits further from the
vertical centre has the tighter chord.

The original layout used fixed per-line offsets from the bottom for fonts far
taller than the gaps between them: every line overlapped the one above and all
three were clipped by the curve. Anchors are computed from measured font heights
for that reason — a taller font must move a line *away* from its neighbours,
never into them, and the tests assert that direction.
