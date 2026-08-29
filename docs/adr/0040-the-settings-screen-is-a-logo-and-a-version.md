---
id: 0040
title: The settings screen's bands are a logo on top and the version below
status: accepted
supersedes: 0037
---

## Context

ADR-0037 put `Candle v1.0` in the settings screen's **top** band as a title, and
ADR-0036 had left the bottom band empty except for the two-second exit hint.
That left the screen bottom-heavy: text at the top, two rows, then nothing.

The app's stated design is extreme minimalism, and the screen was not living up
to it — it had one thing in one band and an absence in the other, which reads as
an unfinished layout rather than a spare one.

## Decision

**A small thing at each end, with the rows between them.**

- **Top band: the candle mark**, a 40×40 drawable emitted by
  `tools/make-icons.ps1` from the same procedural master as the launcher icon
  and the store icon. A logo, not a name.
- **Bottom band: the version**, `v1.0`, in every build.

The app's name goes with the move rather than being duplicated beside the mark.
A logo that needs its own name written next to it is not doing its job.

The bottom band keeps strict precedence, the same shape as the main screen's
(ADR-0005): a swallowed Back shows `HOLD TO EXIT` for two seconds, and the
version is the resting state underneath it. An input that changes nothing on
screen reads as a frozen app, so the hint outranks a number nobody is waiting
for.

## Consequences

**The `DEPLOY-VERIFY` marker moved with the version, in the same commit.** That
is the entire reason it exists: the sentence `deploy.ps1` prints is the
verification procedure (ADR-0034), it named the wrong band once before, and a
wrong one reads as *the sideload did not land*. This is the mechanism's first
real test and it worked — the marker sits beside the draw call, so moving the
draw put the instruction under the same edit.

**The logo is allowed back only because the screen changed.** A 40×40
`logo_small.png` used to sit in the MAIN screen's bottom slot and was deleted,
because that slot must hold a fact about the session in progress (ADR-0005) —
the screen you breathe on is not a place to advertise. This is the settings
screen, which nobody breathes at, and here the mark is a title. `make-icons.ps1`
carries that distinction as a comment so the file's existence is not mistaken
for permission to put it back.

A bitmap is the one thing on either screen that no string test can see, so
`layoutSettingsLogoFitsItsBand` pins its size against the band and the chord.
A square bitmap near the top of a round screen runs out of chord at its corners
long before its centre line, which is the failure this catches.

`Layout.topSlotY` now takes a content height rather than a font height. A font
and a bitmap centre identically, which is why the logo needed no anchor of its
own.
