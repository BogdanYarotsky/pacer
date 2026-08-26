---
id: 0009
title: Back never exits; a held lower button is the only way out
status: accepted
---

## Context

Given ADR-0008, any exit hung on `onBack` fires when a sleeve crosses the glass.

## Decision

The exit moved to `onMenu` — a **held** lower button — which is the one gesture
in the whole investigation the firmware has never been caught forging, confirmed
on the wrist before anything was hung on it.

`System.exit()` ends the app cleanly from any point, so one handler serves both
screens: hold the lower button to quit, from anywhere. Restricting it to the
main screen would have cost a branch, not saved one.

## Consequences

A swallowed Back on the main screen arms the `HOLD TO EXIT` hint for two
seconds, because an input that changes nothing on screen reads as a frozen app,
and because the hint names the gesture that does work. It outranks the
`VIBE OFF` warning in the bottom slot — that is the warning deferred by two
seconds, not crowded out.

This closes six of the six observed exits. It does not close a platform-level
exit that never reaches the delegate, which nothing in the app can prevent and
which has never been observed here.
