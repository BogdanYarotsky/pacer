# Publishing Candle to the Connect IQ Store

The submission is four artifacts — the `.iq` bundle, the 500 px icon, the
listing text, and screenshots — plus a wrist pass that proves the build being
shipped is the build that works. Everything reproducible is scripted; this
file is the order to run it in.

## 1. Wrist verification (before packaging anything)

`just deploy` a debug build and confirm, on the watch:

- [ ] The launcher lists **Candle** with the candle icon.
- [ ] The version on the **`EVERY` screen** (upper button) matches what deploy
      printed (the ONLY proof a sideload landed — MTP cannot be verified from
      the host). The main screen no longer shows it.
- [ ] The upper button opens the `EVERY` screen and the same button closes it;
      Back and a right swipe close it too, and **none of the three ends the
      session** — the cue keeps arriving throughout.
- [ ] A migrated interval: if the watch previously ran Pacer, the `EVERY`
      value equals the old pace's cue interval (e.g. 5.71 bpm → `EVERY 5.25s`).
- [ ] The default cadence counts right against a clock: at `EVERY 5s`,
      one buzz per five seconds, twelve per minute.
- [ ] Tap steps once per tap on all three rows, `EVERY` included; hold repeats
      ~5 steps/s and stops the instant the finger lifts. Both ends of every
      range clamp. Nothing on either screen is a fat-finger away from the wrong
      row now that the controls are this large — check that with a thumb, not
      a fingertip.
- [ ] The clock is current after closing the `EVERY` screen, not a minute stale.
- [ ] The bottom line reads `BATT nn%` and matches what the watch's own
      controls menu says.
- [ ] System vibration off → bottom line reads `VIBE OFF` and the battery
      yields the whole line; on → the battery comes back.
- [ ] **A right swipe on the MAIN screen does nothing, and neither does a
      PRESS of the lower button** — both show `HOLD TO EXIT` for two seconds
      and the session keeps running. This is the phantom-swipe fix; if either
      still closes the app, stop and read the breadcrumb.
- [ ] **HOLDING the lower button exits**, from the main screen and from the
      `EVERY` screen. The next launch shows a `…>M!` breadcrumb (debug only).
- [ ] The phantom swipe-exit hunt: adjust settings unlocked until an
      unwanted exit happens, relaunch, **press the upper button**, and read the
      breadcrumb on its own line above the version. Six events now, not two.
      **Already established (2026-08-25): the firmware synthesizes a real
      KEY_ESC for the gesture** — `R5.P5>B!` after a swipe nobody keyed. What
      this run is for is the ORDER:
      `D0…P5>B!` ⇒ a drag preceded the synthesized key ⇒ gate `onBack` on a
      recent drag; `S1…` ⇒ the wrist raises `onSwipe(SWIPE_RIGHT)` where the
      simulator does not ⇒ gate on that instead, it is cleaner;
      `P5>B!` with no drag or swipe before it ⇒ the firmware is faking the
      whole chain and neither gate works — say so rather than guessing a third;
      `…>S` ⇒ platform-level exit onBack never saw ⇒ only the watch's
      native Lock Screen prevents it — document, do not code around it
      (`configureTouchEvents` stays banned, AGENTS.md rule 3).

## 2. Build the artifacts

```
just test          # 47 unit tests, must be green
just input-test    # 24 real-input checks, must be green
just icons         # regenerates publish/store-icon-500.png + launcher icon
just shot-release  # the screen a Store install shows: no version line
just package       # publish/Candle.iq -- signed release, every product
```

Screenshots for the listing: `shots/vivoactive5.png` from `just shot-release`
(crop the round screen out of the simulator bezel capture).

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
   for it — **Yudemon** or **Elite HRV** — and dial in seconds between cues
   = 60 / bpm / 2. Interval 0.05–15 s in 0.05 s steps; pulse length and
   strength adjustable down to the hardware's own floor.
4. How to drive it, because two things here are unguessable: strength and
   pulse length are on the main screen, a **press of the upper button** opens
   the interval, and **quitting is a HOLD of the lower button** — Back does not
   exit, because this watch's firmware fakes a button press for a right swipe
   and Candle would otherwise end your session when a sleeve touched the glass.
5. Lock the screen during a session (**hold** the upper button → Lock Screen).
6. Free, open source, MIT.

## 4. After approval

- [ ] Install from the store on a clean watch (or after uninstalling the
      sideload — note: uninstalling wipes stored settings; same-key signed
      store install over the sideload upgrades in place instead).
- [ ] Launcher name and icon are Candle's.
- [ ] Main screen's bottom line is the battery (or `VIBE OFF`); the `EVERY`
      screen's slot is empty — no version line, no breadcrumb, no mark.
- [ ] The Connect IQ phone app reports the installed version (the release
      build's substitute for the on-screen version).
- [ ] Tag the repo with the released version and update the README's store
      link.
