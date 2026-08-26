---
id: 0002
title: The two cues per breath are identical and carry no phase
status: accepted
---

## Context

Each breath gets two cues, one at each turn-around. Nothing in them
distinguishes "inhale now" from "exhale now" — the wrist feels a metronome at
twice the breath rate.

## Decision

Keep them identical. Inhale and exhale are the same length (an equal I:E ratio,
chosen because there is no good evidence 4:6 or 1:2 does anything measurable),
so the two boundaries are interchangeable.

## Consequences

What this buys is **free re-entry**: a distraction, a notification buzz, a
missed pulse, even the timer restarting mid-session when the pace is nudged —
every disturbance costs exactly one breath and resolves itself on the next cue.
Nothing to count, no way to be wrong, no wrong beat to start on.

`Attention.vibrate` takes up to 8 `VibeProfile`s, so encoding the phase (one
pulse in, two out) is nearly free to build. **It has been proposed once and was
wrong.** It trades the self-healing property away to fix a problem that only
exists under an asymmetric ratio this app does not use. If the I:E ratio ever
stops being 1:1, revisit; until then the identical cue is load-bearing.
