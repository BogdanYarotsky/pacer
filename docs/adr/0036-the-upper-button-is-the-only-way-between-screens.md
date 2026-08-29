---
id: 0036
title: The upper button is the only way between the screens; BACK is retired
status: accepted
supersedes: 0010
---

## Context

ADR-0010 put a `BACK` button in the settings screen's bottom band, reasoning
that Back is swallowed there (ADR-0008, ADR-0009) and there is no *held* gesture
meaning "go back", so the screen needed a visible control rather than another
hidden one.

That reasoning went looking for a gesture and walked past the hardware. This
watch has two physical buttons and the upper one already does the job: it pushes
the settings screen and pops it again, the same press either way. A drawn button
was invented to replace a gesture, when a button was already there.

## Decision

Navigation is physical, and it is two rules with no screen-dependent clauses:

- **A press of the upper button cycles the two screens** — main to settings,
  settings to main.
- **A HELD lower button exits, from either screen** (ADR-0009, unchanged).

The `BACK` control is deleted: `Display.backLabel`, `Layout.isBackTap`, and the
tap branch in `candleDelegate.onTap` all go with it.

Back stays swallowed on both screens and **both now answer it the same way**,
with `HOLD TO EXIT` for two seconds. ADR-0010 argued the settings screen could
have no hint because a hint would cover the control it described. With the
control gone, the band is free and the two screens stop needing two behaviours:
`onBack` is one path again.

## Consequences

The settings screen's bottom band is empty at rest, and its top band is empty
in a release build (ADR-0032) — so a Store install draws that screen with two
empty bands and the hint is the only thing either one ever shows.

Nothing on the glass says the upper button goes back. That is the cost, and it
is paid in the store description rather than in pixels: a control that cannot be
mis-tapped is worth more on a screen a wearer adjusts mid-session than a label
that can. The gesture is symmetrical and self-teaching — the press that opened
the screen closes it — which is not true of a control you have to find.

`Layout.bottomSlotY` now anchors the same string on both screens, so the band's
one remaining geometric duty is to clear the bottom row's controls; the test
that pinned the `BACK` tap band to the row boundary was rewritten to pin that
instead.
