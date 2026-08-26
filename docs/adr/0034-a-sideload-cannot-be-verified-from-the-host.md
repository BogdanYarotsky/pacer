---
id: 0034
title: A sideload cannot be verified from the host
status: accepted
---

## Context

The vívoactive 5 mounts over MTP, not as a drive letter. The directory listing
lies in both directions — it will show a file that is not there and hide one
that is — and MTP exposes no size the host can trust.

## Decision

Never claim a deploy landed. The **only** proof is on the glass: launch Candle,
press the upper button, read the version off the settings screen (ADR-0032). If
it shows an older version, the watch is still running the old build.

## Consequences

`deploy.ps1` bumps the version before every push for exactly this reason, and
its closing message is the verification procedure — so that message has to
describe the screen the wrist is actually looking at.

It also bumps **before** it checks the watch is connected, so a failed deploy
still burns a version number. After one, use the no-bump recipe or the number
walks for a build nobody has seen.

A differently-signed build with the same app id must be uninstalled first, and
that wipes the stored settings. A same-key signed store install over a sideload
upgrades in place instead.
