# Architecture Decision Records

Every decision in Candle that is not obvious from the code lives here, one file
per decision, referenced from the code by id: `// ADR-0018`.

## The rules

1. **ADRs are append-only.** A decision that changes is never edited — a new ADR
   supersedes it. `0016` says the pace was stored as breaths per minute; `0018`
   says milliseconds and supersedes it. Nobody rewrites `0016`. A stale comment
   is a lie; a superseded ADR is a fact about the past.
2. **Numbers a test can compute do not belong here either.** See ADR-0033.
   Ranges, pixel widths and collision counts live in the tests that measure
   them; an ADR says *why the value matters*, never what it currently is.
3. **Never renumber, never delete.** Ids are referenced from source. Retire a
   decision by superseding it.
4. **Rationale lives here; tripwires stay in the code.** A comment warning that
   `Number / Number` is integer division, or that a `return` after
   `System.exit()` will not compile, is a hazard at the point of use and stays
   inline. If it explains *why a value or a design is what it is*, it belongs in
   an ADR.

`just check-adrs` enforces rules 1 and 3 mechanically, and fails on an ADR that
nothing references. It runs as part of `just test`.

## Format

```
---
id: NNNN
title: ...
status: accepted | superseded
supersedes: NNNN          (optional)
superseded-by: NNNN       (optional)
---

## Context      -- what forced a decision
## Decision     -- what we do
## Consequences -- what it costs, and what must not be "fixed"
```

## Index

Read `0001`–`0004` before changing anything. They are the decisions that look
like bugs.

| | |
|---|---|
| **Product shape** | `0001` haptic only · `0002` identical cues · `0003` delegate never rebuild · `0004` palm safety is the watch's · `0005` the main screen's bottom slot · `0006` the clock and the minute-gated redraw |
| **Input** | `0007` the measured event chain · `0008` the firmware forges KEY_ESC · `0009` back never exits · `0010` back swallowed on both screens |
| **Geometry** | `0011` the chord is not the bounding box · `0012` the row grid and control size · `0013` text must clear the controls · `0014` inert centre text · `0015` glyphs are drawn bars |
| **The interval** | `0016` stored as bpm *(superseded)* · `0017` stored as hundredths *(superseded)* · `0018` stored as milliseconds · `0019` EVERY and PACE are one setting · `0020` 0.01 bpm precision · `0021` EVERY snaps to its ladder · `0022` the range |
| **Settings** | `0023` POWER's two-zone ladder · `0024` PULSE range · `0025` storage keys are on-disk API · `0026` clamp, never reject · `0027` the cached VibeProfile |
| **Structure** | `0028` Rows owns row order · `0029` Display owns drawn strings · `0030` Layout and CandleMath are pure · `0031` annotate leaves, not renderers · `0032` the version is debug-only *(superseded)* · `0033` no computed numbers in prose · `0034` a sideload cannot be verified from the host · `0035` the jungle sourcePath is literal |
| **Navigation and the version** | `0036` the upper button is the only way between screens · `0037` one version drawn as the settings title · `0038` the BPM row draws no caption · `0039` two segments public, three dev · `0040` the settings screen is a logo and a version · `0041` BUZZ and both main defaults are fifty · `0042` one-letter meridiem *(superseded)* · `0043` the clock drops a size and keeps AM/PM · `0044` the UI is custom, not Garmin's |
| **Devices** | `0045` geometry is a proportion of the glass · `0046` one launcher icon per device, at its own size · `0047` which watches Candle supports |
