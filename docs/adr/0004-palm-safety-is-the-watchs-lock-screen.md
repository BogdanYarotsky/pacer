---
id: 0004
title: Palm safety belongs to the watch's Lock Screen, not to Candle
status: accepted
---

## Context

A breathing session is exactly when a sleeve or a palm crosses the glass. An
app-level touch lock is the obvious answer and Candle shipped one.

## Decision

Deleted it. Palm safety is the watch's own Lock Screen — hold the upper button,
Lock Screen. `WatchUi.configureTouchEvents` is **banned** in this codebase.

## Consequences

This is the standing proof of ADR-0003's trade. The touch lock was a real
feature, correctly motivated, and it could leave the **whole watch** needing a
reboot: `configureTouchEvents` changes watch-global state, and an app that dies
holding it does not put it back.

A future agent will find the swipe-exit problem (ADR-0008) and reach for
`configureTouchEvents` as the fix. It is not one. A platform-level exit that
never reaches the delegate is guarded by the native Lock Screen and by nothing
in this app.
