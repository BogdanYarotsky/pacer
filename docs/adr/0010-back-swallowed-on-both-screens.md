---
id: 0010
title: Back is swallowed on both screens; the settings screen has a BACK button
status: superseded
supersedes: 0009
superseded-by: 0036
---

## Context

ADR-0009 stopped Back exiting the app, but left it popping the settings screen —
on the reasoning that landing on the main screen costs a wearer nothing.

That reasoning was about *deliberate* Backs. The forged ones (ADR-0008) raise
the same synthesized `KEY_ESC` there as anywhere, so a sleeve across the glass
closed the settings screen out from under a value being adjusted.

## Decision

Back does nothing on either screen. The settings screen's bottom band is a
**`BACK` button** instead — the whole band is the tap zone, not the width of the
word — and the build version moved to the top band to make room.

## Consequences

A visible target rather than another gesture, and the asymmetry with the main
screen is deliberate: the main screen answers a swallowed Back with a *hint*
naming a held button, because there is a held gesture meaning "quit". There is
no held gesture meaning "go back", and inventing one would be a hidden control
on a screen with room for a visible one.

The settings screen therefore needs no hint — a hint would have to cover the
control it was describing.

`BACK` draws in **every** build, unlike the version above it (ADR-0032). On a
Store install the upper button still pops the screen, but nothing on the glass
says so, which makes `BACK` the only exit a first-time wearer can see.

The tap band must stop exactly where the rows stop; a band one row-height taller
would eat the bottom row's `-` control, and a test pins that boundary.
