---
id: 0032
title: The build version is debug-only and lives on the settings screen
status: superseded
superseded-by: 0037
---

## Context

A sideload cannot be verified from the host (ADR-0034), so the on-screen version
is the only proof of which build is running. A Store install has no such
problem: the Connect IQ app reports the installed version.

## Decision

Draw it in debug builds only, on the settings screen, never on the main screen.
`deploy.ps1` bumps it on every sideload.

## Consequences

Drawing it in a release build would be the duplication ADR-0003 rejects
everywhere else.

This is safe **precisely because every sideload is a debug build** —
`deploy.ps1` calls the build without a release flag. If a release flag is ever
added to the deploy path this verification loop dies silently: the watch simply
stops showing a version and every deploy looks identical.

It is one button press away rather than in front of you all session, which is
the right trade for something you read once after a deploy and never again while
breathing (ADR-0005).

It moved from the bottom band to the top when the `BACK` button took the bottom
(ADR-0010). The swap reads correctly on its own terms: the version is a label,
and the thing at the bottom is now something you press.

The version constant and the deploy script's closing message have to move
together — that script greps the source for the constant.
