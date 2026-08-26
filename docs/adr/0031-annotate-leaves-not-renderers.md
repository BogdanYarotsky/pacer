---
id: 0031
title: Build-mode annotations go on leaf functions, never on renderers
status: accepted
---

## Context

`(:debug)` and `(:release)` drop code at compile time. **Unit tests compile with
`-t`, which is a debug build, so tests cannot see `(:release)` code at all.**

## Decision

Annotate tiny leaf predicates, keep call sites unconditional. A function that
*decides* whether something is drawn is annotated; the function that *draws* it
is not.

## Consequences

Annotating a rendering function would leave the release output measured by
nothing and shipped to the only audience that cannot report it clipped.

Because the predicate is a parameter rather than a branch, the layout tests pass
both states explicitly and measure both outputs. Reading the real predicate in a
test would always answer "debug".

`just shot-release` exists for the same reason: it is the only way to see what a
Store install actually draws.

Debug-only tracing costs nothing on the watch — the blocks are gone at compile
time — but the traces are not decoration either: `tests/input-behaviour.ps1`
asserts on them (ADR-0007).
