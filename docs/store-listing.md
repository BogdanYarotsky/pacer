# Connect IQ store listing — the text to paste

The submission walk-through is `PUBLISHING.md`; this file is only the copy.
It lives in the repo so it changes when the app changes, rather than being
retyped from memory into a web form once a year.

## The rule this copy is written under

**Garmin App Review Guidelines §1(c), Medical Apps.** An app "intended for use
in the diagnosis, cure, mitigation, treatment or prevention of disease or other
conditions" must be backed by regulatory documentation; otherwise the
description must not indicate any such use and must be "for informational
purposes only."

Candle is a metronome. It is described here as a metronome. **Nothing below
claims a health outcome** — no HRV improvement, no stress or anxiety benefit, no
therapeutic effect — and nothing should be added that does. The enthusiasm
belongs in a blog post, not in this box.

Two more that bite this app specifically:

- **§1(f) no apps for children under 13.** The repo justifies the 10 bpm ceiling
  partly by citing children's resonance bands. That reasoning stays in the
  README. It must not appear here, because it reads as designing for children.
- **§4(a) describe accurately.** Name every device, and name each one's
  buttons by what its own manual calls them: the two gestures are the same on
  every watch, the buttons that carry them are not (ADR-0047).

---

## Fields

| Field | Value |
| --- | --- |
| App name | `Candle: Resonance Breathing Pacer` (33 chars) |
| Type | Watch App |
| Category | Health & Fitness |
| Devices | vívoactive 5, Forerunner 955 / 955 Solar — the store reads the list off the `.iq`; it is `manifest.xml` that decides |
| Version | whatever `just package` printed |
| Price | Free |
| Permissions | none — `<iq:permissions/>` is empty |
| Source | https://github.com/BogdanYarotsky/candle-rfb |

---

## What's new — the update form's changelog box

One line per public version, newest first. The form takes plain text: no
markdown, no `<` or `>`, which the upload has been seen to reject.

```
1.1  Adds the Forerunner 955 (and 955 Solar). The layout now scales to the
     watch; nothing about the cue or the settings changed.
1.0  First release. vivoactive 5.
```

---

## Description

> Candle is a haptic metronome for paced breathing. It vibrates twice per
> breath — once at the top, once at the bottom — and that is all it does.
>
> **The screen never shows your breath.** There is no expanding circle and
> nothing to watch. The cue is on your wrist, so you can practise with your eyes
> closed, in a meeting, or walking, and nobody else knows it is running. The
> display is deliberately inert.
>
> **One cue every 5 seconds by default** — ten seconds per breath, 0.1 Hz, the
> rate usually called coherent or resonance-frequency breathing.
>
> **Set your own rate.** Resonance frequency is individual. Measure yours with a
> tool built for it — Yudemon HRV's Journey Mode and Elite HRV are two — and
> type the breathing rate it reports straight in. No arithmetic and no rounding:
> the BPM row steps by 0.01 bpm, which is the precision those tools report at.
>
> The interval screen carries the same setting in both units. `EVERY` is seconds
> between cues, in 0.05 s steps; the row below it is the same setting in breaths
> per minute. Move either and the other follows. If breaths-per-minute means
> nothing to you, ignore it and work `EVERY` — the number below will follow
> along.
>
> **Equal inhale and exhale, always.** One vibration at each turn-around, both
> identical, carrying no phase — so when your attention drifts you can rejoin on
> any pulse without working out which half you are in. There are no holds and no
> pauses. That is the design, not a missing feature.
>
> **Controls**
> - Vibration strength (`POWER`) and buzz length (`BUZZ`) are on the main
>   screen. Both adjust down to the hardware's own floor.
> - **Press the upper-right button** for the interval screen — the Action
>   button on the vívoactive 5, START on the Forerunner 955. The same press
>   brings you back. It is the only way between the two screens.
> - **Hold the menu button to quit**, from either screen: the lower button on
>   the vívoactive 5, UP on the Forerunner 955. Back does not exit — the
>   vívoactive 5's firmware raises a real button press for a right swipe, so a
>   sleeve across the glass would otherwise end your session.
> - To lock the screen during a session, open the watch's controls menu (hold
>   the upper button on the vívoactive 5, hold LIGHT on the Forerunner 955)
>   and choose Lock — the watch's own lock, not a copy of it.
>
> The main screen shows the time and the battery. Nothing else moves.
>
> Free and open source under the MIT licence. For informational purposes only;
> it is not a medical device and is not intended to diagnose, treat, cure or
> prevent any condition.

---

## Notes on choices in the copy above

**"the rate usually called coherent or resonance-frequency breathing"** names a
practice, not an outcome. That is the line: describing what people call the
thing is fine, asserting what it does to a body is not.

**Yudemon and Elite HRV are named as suggestions**, not as integrations. Candle
does not talk to them and must not imply it does (§4(a) forbids unearned
compatibility claims). If a reviewer objects to third-party names at all, cut
them to "an HRV assessment tool that reports a resonance frequency" — the copy
survives it.

**The swipe explanation is kept** even though it is unusual for a store listing.
Quitting by holding a button is genuinely unguessable, and a wearer who cannot
work out how to leave an app writes a one-star review rather than a support
email. Explaining it here is cheaper than a rating.

**Buttons are named per device**, because the app's two gestures land on
different physical buttons on each watch (ADR-0047). Adding a device means
adding its button names to those three bullets — and only there; the app's own
`HOLD TO EXIT` hint names no button on purpose.

**No screenshots of the settings screen with fiddled values.** The simulator
keeps whatever the previous run left it holding — see `PUBLISHING.md` §2.
