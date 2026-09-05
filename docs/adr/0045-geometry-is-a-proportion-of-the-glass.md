---
id: 0045
title: Geometry is a proportion of the glass, not a pixel count
status: accepted
---

## Context

Candle shipped for one watch, and `Layout` carried that watch's numbers as
constants: a row height, a control inset and radius, a hit-zone edge, all in
pixels of one glass, with `DISPLAY_WIDTH` written into the module and handed to
the hit map by the delegate. The tests measured that one glass by name.

The Forerunner 955 is the second device: a round glass a third smaller, whose
font set happens to scale with it — measured on every run, never assumed.
Nothing about the design wanted to change; only its size did. And the stated
direction after it is every Garmin watch with a motor, which rules out a
constant set per device before the second one is even in.

Garmin's own guidance is the plain one: ask the `Dc` how big the screen is,
never write a resolution into code, and keep per-device resources where a
device genuinely differs (ADR-0046).

## Decision

**One reference design, scaled to the glass in hand.**

- The tuned values stay, renamed `*_REF`, and are read as proportions of
  `REFERENCE_WIDTH` — the glass they were tuned on. `Layout.scaled` returns a
  reference value at the size it is handed, rounded to nearest, and is the
  **identity on the reference glass**: the first device draws pixel for pixel
  what it drew before, so the shipped layout *is* the reference rather than an
  approximation of it. A test pins the identity.
- Every geometry function takes the glass as an argument, as they already did;
  what changed is that the constants they used to read are functions of it too.
  Vertical sizes follow the height and horizontal ones the width — equal on
  every round glass, and spelled twice so a glass where they differ gets a
  stretched reference rather than a wrong one.
- The glyph bars go through `oddScaled`, which forces the odd parity ADR-0015
  requires on any glass rather than hoping the rounding lands on it.
- The view reads `dc.getWidth()`; the delegate, which has no `Dc`, reads
  `System.getDeviceSettings()` once. `DISPLAY_WIDTH` is gone.
- The tests measure **the device the runner is on**: the glass from the device
  settings, the fonts from a `Dc` on it. `layoutRealLinesFitOnVivoactive5`
  became `layoutRealLinesFitTheGlass`. `just test <device>` is therefore the
  proof for that device and no other; no device inherits another's verdict
  (ADR-0047).
- `tests/input-behaviour.ps1` carries no coordinates any more. The delegate
  prints the geometry it decodes taps against as a debug trace, one line per
  screen, and the script aims by it. The line's shape is part of the contract
  between the two.

## Consequences

Fonts do not scale with the glass by any rule the SDK promises. That they did
on the first two devices is a measurement, not a design, and it is why every
device runs the sweeps against its own metrics. A device whose fonts run large
for its glass fails `layoutHitZonesClearRealisticText` or a chord sweep with
the string that broke — which is the correct outcome, and a `Layout` problem to
solve, not a device to skip.

The chord maths still models a circle in a square. `layoutGlassIsRoundAndSquare`
pins `SCREEN_SHAPE_ROUND` and equal sides, so a semi-round or rectangular watch
fails at `just test` with a sentence instead of drawing text off the edge.
Teaching `halfChordAt` a second shape is the work such a device would need, and
it is deliberately not done here.

Thresholds that were pixels of the first glass — the air between stacked
controls, a glyph's clearance from its ring — are proportions now too. Kept in
pixels they would have passed a small glass on a margin sized for a large one.

The pen has a floor of one pixel. A glass small enough to scale it to zero
would otherwise lose the control's border with no test to say so.

Recipes that default to one device still do, because the loop is
edit → build → test on the device you are holding. `just test-all`,
`just all-devices` and `just package` are where every product is exercised.
