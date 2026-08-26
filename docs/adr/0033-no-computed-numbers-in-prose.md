---
id: 0033
title: Never write a number a test can compute
status: accepted
---

## Context

Measured 2026-08-26, before this ADR folder existed: `source/` was **54%
comment**, the three markdown files were **1457 lines**, and changing the
interval's stored unit — one unit, one step — took **12 files and 666
insertions**, leaving ten stale facts behind. One of them had been stale before
that session started. The pattern compounds unattended.

## Decision

The volume was never the problem. Which facts the prose states is. Two kinds of
sentence live in these files with opposite lifetimes:

- **Rationale** — *why* a value is what it is. Durable. It survives every tuning
  pass, and it is why this repo is navigable after months away. Keep writing it.
- **Computation** — *what the value works out to*. Pixel widths, collision
  counts, arithmetic results. **Volatile.** Every one dies when a constant
  moves, and nothing fails when it does.

**Do not write the second kind.** If a test can compute it, the test computes it
and `logger.debug`s it. A number typed into a comment is a number with no owner.

## Consequences

This ADR folder exists to give rationale one home. ADRs are **append-only**: a
decision that changes is superseded, never edited, which is why a stale ADR is
history rather than a lie.

Docs point rather than copy. README and PUBLISHING name rows and behaviours; the
ranges and steps live in `candleApp` and the tests, and every number restated in
a doc is a fourth copy waiting to rot.

`tools/check-adrs.ps1` runs inside `just test` and fails on a dangling reference
or an accepted ADR nothing points at. That makes this the first prose in the
repo that a build can reject.

**Tripwires stay inline.** A comment warning that `Number / Number` is integer
division, or that a `return` after `System.exit()` will not compile, is a hazard
at the point of use, not a decision. Moving those into an ADR would mean opening
a file to learn why you cannot add a line.
