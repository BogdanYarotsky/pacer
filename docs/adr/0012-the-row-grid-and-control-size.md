---
id: 0012
title: The row grid is centred on the glass, and the controls are as large as it allows
status: accepted
---

## Context

The control circles run out of room before the text does, and on a round screen
every pixel a row sits away from the vertical centre is a pixel its circles have
to give back.

## Decision

Centre the row block on the glass rather than hanging it from a fixed top edge,
and size the controls against the real circle-in-circle bound:

```
sqrt((halfWidth - inset)^2 + (rowCentre - centre)^2) + radius + pen <= halfWidth
```

The pen is counted as if the whole stroke fell outside the radius — the
conservative reading of an undocumented detail.

## Consequences

Hanging a two-row grid off the old three-row top edge would have left the rows
lopsided in the band and the outer one further from centre than it needs to be,
for no gain.

The chord-at-tangent check this replaced was strictly tighter than the real
bound and rejected radii the glass fits. An earlier radius left about a pixel of
margin, which antialiasing visibly clipped — hence the margin is asserted, not
eyeballed.

Adjacent rows must also not run their circles into each other. The chord maths
cannot see that: both circles are comfortably on the glass while overlapping.

The settings screen's rows sit closer to the centre line than the main screen's,
where the same circle has more air. They are drawn at the same radius anyway — a
control that changed size when you walked to another screen would read as a
different control.
