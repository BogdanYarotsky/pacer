---
id: 0039
title: Two segments is public, three is a dev build, and package refuses three
status: accepted
supersedes: 0037
---

## Context

ADR-0037 made one number serve two readers — a wearer quoting a version in a bug
report, and a developer proving a sideload landed — and tightened it to one
digit each side of the dot so that every string is four characters and the title
band is never sized for versions nobody will ship.

That rule held for the *published* number and broke for the working one. Every
sideload bumped it, so a run of iteration between two releases either burned
public numbers (1.3 published, then 1.7 published) or forced the developer to
avoid deploying. Neither is acceptable: a deploy has to be free, because a
deploy against an unplugged watch has already silently spent a version twice.

**Only ADR-0037's numbering clause is replaced here.** Its substance — one
version, drawn in every build, as the settings screen's title, with no
`(:debug)`/`(:release)` predicate — stands, which is why it stays accepted.

## Decision

**The shape of the string says what the build is.**

| shape | meaning |
| --- | --- |
| `1.4` | a **public** version. One digit each side, the minor rolls (`1.9` → `2.0`). The only shape the store ever sees. |
| `1.4.12` | a **dev** build — the 12th sideload since `1.4`. Never published, never publishable. |

- `just deploy` bumps the **iteration**: `1.4` → `1.4.1` → `1.4.2`. It never
  touches the public number, so a deploy costs nothing.
- `just release` finalises: a dev version becomes the next public one
  (`1.3.12` → `1.4`); a version that is **already public is left alone**, which
  is what makes a first release possible at `1.0` rather than `1.1`.
- **`just package` refuses a three-segment version.** This is the one rigid
  guard, and it is enough on its own: there is exactly one route to
  `publish/Candle.iq` and it runs through that check.

The scheme lives in `tools/version.ps1`, dot-sourced by all three, so no script
carries its own idea of what a version is.

## Consequences

Nothing has to be remembered. A bug report quoting `1.4.12` is self-evidently
not a store install — to the developer, and to a stranger comparing it against
the listing. The rule that matters is enforced by a script rather than by
discipline, so the rest of the workflow can stay loose.

`just release` **stops before packaging**, printing the next command instead of
running it. The wrist pass sits in that gap and cannot be automated: a sideload
cannot be verified from the host (ADR-0034), so a person reads the number off
the glass. A recipe that ran through to `package` would produce the submission
artifact before the only test that matters had been taken.

The iteration is capped at three digits, which is a layout fact rather than a
taste one — `Candle v9.9.999` fits the title band and a fourth digit does not.
`layoutRealLinesFitTheGlass` (then named `layoutRealLinesFitOnVivoactive5`)
pins it; `version.ps1` fails with a sentence before pixels get clipped.

The unhappy path is named rather than automated: if a wrist pass sends you back
after `release` has finalised `1.4`, iterating gives `1.4.1` and the next
release would reach for `1.5`, skipping a number that never shipped.
`release -SetVersion 1.4` is the answer, and `release` prints it at the point
where it is needed.
