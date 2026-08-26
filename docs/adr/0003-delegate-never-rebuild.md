---
id: 0003
title: Candle builds nothing the watch or another app already does
status: accepted
---

## Context

Every capability the app grows is permanent surface that can break.

## Decision

Where a capability exists outside the app, delegate to it. The test for any
proposed feature: does the watch, or an app that can run in parallel, already do
this? If yes, it does not belong here.

## Consequences

Two things follow that read as missing features and are not:

- **No session timer.** No duration setting, no elapsed display, no auto-stop,
  no start button. Someone wanting a time-bound session runs a timer app
  alongside, which the watch does perfectly well.
- **No app-level touch lock** — see ADR-0004 for what reimplementing that cost.

**The clock and the battery fail this test on its face and stay anyway.** The
watch tells you both perfectly well; the charge is a button *hold* away in the
controls menu. They stay because the rule is about *capabilities*, not
*readings*, and what the watch cannot do is show you either without taking you
off this screen. Leaving a breathing session to check whether the watch will
last it is the interruption the app exists to prevent. See ADR-0005, ADR-0006.
