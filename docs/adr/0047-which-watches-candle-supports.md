---
id: 0047
title: Which watches Candle supports, and what a new one has to pass
status: accepted
---

## Context

v1.0 shipped for the vívoactive 5 alone. The Forerunner 955 is the second, and
the direction after it is every Garmin watch with a vibration motor that can run
the app. "Every watch" is a list that changes every year, so what is worth
writing down is not the list but the rule that produces it — and the rule has
to be one a script can check, because the failure it prevents is a store
listing that promises a device the app is unusable on.

## Decision

A device belongs in `manifest.xml` when all of these hold.
`tools/check-devices.ps1` enforces the mechanical ones, and refuses `just test`
and `just package` when one fails; the rest are a person's job.

1. **Round, and square in its bounding box.** The chord maths models a circle
   (ADR-0011, ADR-0045). Semi-round and rectangular glasses need work that has
   not been done.
2. **A touchscreen.** Every value is changed by a tap on the glass, and nothing
   else changes one. On a watch without touch Candle would show its settings
   and offer no way to move them. Steering a row with physical UP/DOWN was
   considered with the focus model it would need and declined (ADR-0044).
3. **A vibration motor.** The app is nothing else (ADR-0001). Every Garmin
   watch has one and the SDK config does not say, so this is a fact to know
   rather than a field to read.
4. **Connect IQ on the device at or above the manifest's `minApiLevel`.** What
   the code actually calls is checked by the compiler against each device's own
   API table, so a build that succeeds for a device is the proof it runs there.
5. **Its own simulator pass.** `just test <id>` green, `just input-test <id>`
   green, and `just shot <id>` and `just shot-settings <id>` looked at by a
   person, before the manifest gains the line. No device inherits another's
   verdict (ADR-0045).

**On buttons.** The app's two gestures are *press the upper-right button* to
cycle the screens and *hold the menu button* to quit. On the vívoactive 5 the
menu hold is its lower button; on the Forerunner 955 it is UP, on the left. The
exit hint says `HOLD TO EXIT` and names no button on purpose: each device's own
manual names it, and the store listing spells out both.

## Consequences

The Forerunner 955's BACK button is swallowed exactly as the vívoactive 5's is
(ADR-0009): a press shows the hint and changes nothing. There is no measured
firmware forgery to guard against on it, and none is assumed; Back being
harmless is a property of the app, not a bet on any one firmware. What the 955
adds is UP and DOWN as physical keys, which arrive as page turns and are
swallowed as page turns always were. Its palm-over-the-glass gesture returns to
the watch face at the firmware level, which is the exit ADR-0004 already says
the app cannot see and does not try to.

The listing's device-specific instructions are the honest cost of the custom UI
(ADR-0044) multiplied by the device count. It is one sentence per device, in
`docs/store-listing.md`.

A watch that satisfies the rule and fails its sweep is a `Layout` problem to
fix, not a device to skip: the design is one proportion set, and a glass it
does not fit is information about the design.

Adding a device is four steps and no guesswork: add the product to the
manifest, download its config with
`connect-iq-sdk-manager device download --manifest manifest.xml --include-fonts`,
run `just icons`, then walk the passes above. `check-devices` says which step
was skipped.
