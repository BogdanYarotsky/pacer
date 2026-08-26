---
id: 0017
title: The interval is stored as hundredths of a second between cues
status: superseded
supersedes: 0016
superseded-by: 0018
---

## Context

ADR-0016's stored rate was not what the timer ran, and the translated line did
not fit.

## Decision

Store the cue interval directly, in hundredths of a second. The row shows the
bare number with no translation: one buzz every that many seconds, checkable
against any clock by counting one gap.

## Consequences

The unit changed, so this was a **new key** and not a rename — see ADR-0025.

The floor was inherited rather than chosen: the platform's documented `Timer`
minimum. Nobody argued for it, and that mattered later (ADR-0022).

Superseded by ADR-0018 when the PACE row needed a precision hundredths cannot
represent.
