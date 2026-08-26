---
id: 0029
title: Display owns every drawn string -- measure what you draw
status: accepted
---

## Context

The layout tests measure rendered text against the round-screen chord, and that
measurement is only worth anything if it measures the strings the view actually
draws.

They already drifted once: a fit test asserted a string the view had stopped
drawing several commits earlier. The test stayed green while measuring something
that no longer existed.

## Decision

Every string the view draws comes from `Display`, and the layout tests read them
from the same place. A literal caption in the view, or a second copy of a
concatenation in a test, is exactly that drift.

## Consequences

Captions are display words **only**, deliberately decoupled from storage keys.
Two of them do not match the code underneath, and that is fine — a caption can
be re-worded in one file, while the keys those settings are saved under are on a
watch's disk and cannot be re-worded at all (ADR-0025).

Captions are looked up by row **identity**, never by position, which is what let
a row move to a screen of its own without a single string changing.

Row lines are composed in one function that takes the row and the value, so the
composition is not repeated at both call sites. The value is passed in because
the view wants the one a watch is holding and the sweep wants every one a watch
could hold.
