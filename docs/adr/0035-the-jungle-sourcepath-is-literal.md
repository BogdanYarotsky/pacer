---
id: 0035
title: The jungle sourcePath stays literal
status: accepted
---

## Context

`tests/` holds `(:test)`-annotated functions only. Per the SDK's unit testing
guide that code is not included in debug or release executables — it is compiled
in only when the compiler is passed the unit-test flag — so adding it to the
source path costs nothing in a normal build.

## Decision

`base.sourcePath` lists `source;tests` **explicitly**. Never the
self-referencing form.

## Consequences

The self-referencing form expands to the project root, which drags the
gitignored SDK junctions into the build and fails with hundreds of
undefined-symbol errors from Garmin's sample apps.

Because tests are in the source path but their bodies are dropped without the
flag, **a normal build does not typecheck them.** Compiling the unit-test build
is what catches a rename in a test file, and it opens no simulator — which makes
it the cheap check to run before the expensive one.
