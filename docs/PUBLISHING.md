# Publishing Candle to the Connect IQ Store

The submission is four artifacts — the `.iq` bundle, the 500 px icon, the
listing text, and screenshots — plus a wrist pass that proves the build being
shipped is the build that works. Everything reproducible is scripted; this
file is the order to run it in.

## 1. Wrist verification (before packaging anything)

`just deploy` a debug build and confirm, on the watch:

- [ ] The launcher lists **Candle** with the candle icon.
- [ ] The version at the **TOP of the settings screen** (upper button) matches
      what deploy printed (the ONLY proof a sideload landed — MTP cannot be
      verified from the host). The main screen does not show it.
- [ ] **The upper button is the ONLY way between the screens** — it opens the
      settings screen and the same press closes it. Neither ends the session;
      the cue keeps arriving throughout. There is no `BACK` button any more
      (ADR-0036), so the bottom band of the settings screen is empty.
- [ ] **A right swipe and a lower-button press do NOTHING on the settings
      screen**, and both show `HOLD TO EXIT` there exactly as on the main
      screen. This is the fix for the swipe that was closing it mid-adjustment.
      Adjust a value, brush right across the glass, and the screen must stay put
      with the value intact.
- [ ] **A tap anywhere in the bottom band does nothing.** It was a `BACK` button
      until ADR-0036; a tap that still navigates means the control came back.
- [ ] **A migrated interval.** The stored unit has changed twice, and both
      conversions still run, so a measured frequency must survive an upgrade
      rather than reset to `5s`. From the previous build (hundredths of a
      second) the value carries over unchanged; from the original Pacer build
      (hundredths of a bpm) 5.71 bpm arrives as `EVERY 5.25s` / `PACE 5.71bpm`.
- [ ] **The two views of one setting.** On the settings screen a `PACE` tap
      moves `EVERY` and vice versa, in OPPOSITE directions — `PACE +` shortens
      the interval, because more breaths per minute is less time between cues.
      Dial `PACE` to `5.5bpm` and `EVERY` should read `5.45s`. Then tap
      `PACE +` and `PACE −` and it must come back to `5.5bpm` exactly, from
      wherever `EVERY` had been left. Both ends clamp, and the two rows' ends
      are the same two places: `2bpm` is `15s`, `10bpm` is `3s`.
- [ ] **`PACE` steps by 0.01 bpm** — every tap moves it, all the way to
      `10bpm`. There must be no tap anywhere in the range that changes nothing.
- [ ] **`EVERY` taps SNAP to the ladder.** Set `PACE 5.73bpm` (`EVERY` reads
      `5.24s`), then tap `EVERY −` three times: `5.2s`, `5.15s`, `5.1s`. Landing
      on a round tenth from an off-ladder value is the whole point of this.
- [ ] The default cadence counts right against a clock: at `EVERY 5s`,
      one buzz per five seconds, twelve per minute.
- [ ] Tap steps once per tap on all four rows, `PACE` included; hold repeats
      ~5 steps/s and stops the instant the finger lifts. Both ends of every
      range clamp. Nothing on either screen is a fat-finger away from the wrong
      row now that the controls are this large — check that with a thumb, not
      a fingertip.
- [ ] The clock is current after closing the settings screen, not a minute stale.
- [ ] The bottom line reads `BATTERY nn%` and matches what the watch's own
      controls menu says.
- [ ] System vibration off → bottom line reads `VIBE OFF` and the battery
      yields the whole line; on → the battery comes back.
- [ ] **A right swipe on the MAIN screen does nothing, and neither does a
      PRESS of the lower button** — both show `HOLD TO EXIT` for two seconds
      and the session keeps running. This is the phantom-swipe fix, and it is
      the single most important line on this list; if either still closes the
      app, stop and say so rather than working around it.
- [ ] **HOLDING the lower button exits**, from the main screen and from the
      settings screen.

The phantom swipe-exit hunt is **CLOSED** and its instrument is gone — the
`ExitForensics` breadcrumb was deleted on 2026-08-25, once it had caught the
firmware forging `KEY_ESC`. AGENTS.md "THE PHANTOM SWIPE-EXIT, SOLVED" holds
the six wrist chains and the reasoning. Do not re-derive it, and do not spend a
session provoking exits to reproduce it. If the app closes itself anyway, the
breadcrumb is a thing to rebuild deliberately, not to go looking for.

## 2. Build the artifacts

```
just test          # the unit suite, must be green
just input-test    # the real-input checks, must be green
just icons         # regenerates publish/store-icon-500.png + launcher icon
just shot-release  # the screen a Store install shows: no version line
just package       # publish/Candle.iq -- signed release, every product
```

Screenshots for the listing: `shots/vivoactive5.png` from `just shot-release`
(crop the round screen out of the simulator bezel capture).

**Check the values in that capture before you use it.** The simulator keeps
whatever settings the previous run left it holding, so the shot is of a watch
someone has already fiddled with — today's read `POWER 100%` and `PULSE 240ms`
against defaults of 20% and 100 ms. A listing screenshot should show the
defaults a new install starts on: `POWER 20%`, `PULSE 100ms`, `EVERY 5s` and
`PACE 6bpm` on the settings screen. Tap them back in the simulator and re-shoot;
the tests restore what they find and cannot be blamed for this.

## 3. The store form

| Field | Value |
| --- | --- |
| App name | `Candle: Haptic Resonance Breathing Frequency Pacer` (50 chars) |
| On-device name | Stays **Candle** — it comes from the manifest's AppName resource, not the form |
| Type | Watch App |
| Category | Health & Fitness |
| Devices | vívoactive 5 |
| Icon | `publish/store-icon-500.png` (500×500 sRGB, ~10 px padding) |
| Permissions | None — the manifest's `<iq:permissions/>` is empty; say so if asked |
| Price | Free |
| Source | Link the public repository (MIT) |

Description — cover, in roughly this order:

1. What it is: a haptic metronome for resonance-frequency (coherent)
   breathing. Two identical vibrations per breath, one at each turn-around.
   The screen never signals the breath; the wrist does.
2. The default: one cue every 5 seconds — 10 s per breath, 0.1 Hz, the
   Lehrer protocol's canonical frequency.
3. That resonance frequency is individual: measure yours with a tool built
   for it — **Yudemon** or **Elite HRV** — and type the breathing rate it
   reports straight into the `PACE` row. No arithmetic, and no rounding: `PACE`
   matches the 0.01 bpm precision those tools report. `PACE` (2–10 bpm in
   0.01 steps) and `EVERY` (3–15 s in 0.05 s steps) are the same setting in the
   two units, on one screen, each following the other. Pulse length and
   strength adjust down to the hardware's own floor.
4. How to drive it, because two things here are unguessable: strength and
   pulse length are on the main screen, a **press of the upper button** opens
   the interval, and **quitting is a HOLD of the lower button** — Back does not
   exit, because this watch's firmware fakes a button press for a right swipe
   and Candle would otherwise end your session when a sleeve touched the glass.
5. The **same upper button** brings you back — one press cycles the two
   screens, in both directions, and it is the only thing that does. Back and
   swipes do nothing on either screen; nothing on the glass navigates.
6. Lock the screen during a session (**hold** the upper button → Lock Screen).
7. Free, open source, MIT.

## 4. After approval

- [ ] Install from the store on a clean watch (or after uninstalling the
      sideload — note: uninstalling wipes stored settings; same-key signed
      store install over the sideload upgrades in place instead).
- [ ] Launcher name and icon are Candle's.
- [ ] Main screen's bottom line is the battery (or `VIBE OFF`). The settings
      screen draws NOTHING in either band — the version is debug-only
      (ADR-0032) and the bottom band is the exit hint's, which only speaks for
      two seconds after a Back (ADR-0036). Two empty bands is correct here.
- [ ] The Connect IQ phone app reports the installed version (the release
      build's substitute for the on-screen version).
- [ ] Tag the repo with the released version and update the README's store
      link.
