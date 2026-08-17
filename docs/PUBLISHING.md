# Publishing Candle to the Connect IQ Store

The submission is four artifacts — the `.iq` bundle, the 500 px icon, the
listing text, and screenshots — plus a wrist pass that proves the build being
shipped is the build that works. Everything reproducible is scripted; this
file is the order to run it in.

## 1. Wrist verification (before packaging anything)

`just deploy` a debug build and confirm, on the watch:

- [ ] The launcher lists **Candle** with the candle icon.
- [ ] The on-screen version matches what deploy printed (the ONLY proof a
      sideload landed — MTP cannot be verified from the host).
- [ ] A migrated interval: if the watch previously ran Pacer, the `EVERY`
      value equals the old pace's cue interval (e.g. 5.71 bpm → `EVERY 5.25s`).
- [ ] The default cadence counts right against a clock: at `EVERY 5s`,
      one buzz per five seconds, twelve per minute.
- [ ] Tap steps once per tap on all three rows; hold repeats ~5 steps/s and
      stops the instant the finger lifts. Both ends of every range clamp.
- [ ] System vibration off → bottom line reads `VIBE OFF`; on → it clears.
- [ ] A right swipe does nothing; the lower button exits immediately; the
      next launch shows the `P5>B!` breadcrumb (debug builds only).
- [ ] The phantom swipe-exit hunt: adjust settings unlocked until an
      unwanted exit happens, relaunch, read the breadcrumb:
      `T.P5>B!` or `P5>B!` after a swipe you never keyed ⇒ the firmware
      synthesizes a real KEY_ESC (design the gate fix from that chain);
      `…>S` ⇒ platform-level exit onBack never saw ⇒ only the watch's
      native Lock Screen prevents it — document, do not code around it
      (`configureTouchEvents` stays banned, AGENTS.md rule 3).

## 2. Build the artifacts

```
just test          # 44 unit tests, must be green
just input-test    # 14 real-input checks, must be green
just icons         # regenerates publish/store-icon-500.png (gitignored)
just shot-release  # the screen a Store install shows: mark, no version
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
4. Lock the screen during a session (hold upper button → Lock Screen);
   the lower button exits.
5. Free, open source, MIT.

## 4. After approval

- [ ] Install from the store on a clean watch (or after uninstalling the
      sideload — note: uninstalling wipes stored settings; same-key signed
      store install over the sideload upgrades in place instead).
- [ ] Launcher name and icon are Candle's.
- [ ] Bottom slot shows the candle mark — no version line, no breadcrumb.
- [ ] The Connect IQ phone app reports the installed version (the release
      build's substitute for the on-screen version).
- [ ] Tag the repo with the released version and update the README's store
      link.
