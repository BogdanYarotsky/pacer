# Publishing Candle to the Connect IQ Store

The submission is four artifacts — the `.iq` bundle, the 500 px icon, the
listing text, and screenshots — plus a wrist pass that proves the build being
shipped is the build that works. Everything reproducible is scripted; this
file is the order to run it in.

## 1. Wrist verification (before packaging anything)

`just deploy` a debug build and confirm, on the watch:

- [ ] The launcher lists **Candle** with the candle icon.
- [ ] The title **`Candle v<n>` at the TOP of the settings screen** (upper
      button) matches what deploy printed — the ONLY proof a sideload landed,
      since MTP cannot be verified from the host. The main screen does not show
      it. It is drawn in release builds too now (ADR-0037), so this line also
      checks what a Store install will show.
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
      (hundredths of a bpm) 5.71 bpm arrives as `EVERY 5.25s` / `5.71 BPM`.
- [ ] **The second row draws no caption** — it reads `6 BPM`, not `PACE 6bpm`
      (ADR-0038). The unit is the caption.
- [ ] **The two views of one setting.** On the settings screen a `BPM` tap
      moves `EVERY` and vice versa, in OPPOSITE directions — `BPM +` shortens
      the interval, because more breaths per minute is less time between cues.
      Dial `BPM` to `5.5 BPM` and `EVERY` should read `5.45s`. Then tap
      `BPM +` and `BPM −` and it must come back to `5.5 BPM` exactly, from
      wherever `EVERY` had been left. Both ends clamp, and the two rows' ends
      are the same two places: `2 BPM` is `15s`, `10 BPM` is `3s`.
- [ ] **`BPM` steps by 0.01** — every tap moves it, all the way to `10 BPM`.
      There must be no tap anywhere in the range that changes nothing.
- [ ] **`EVERY` taps SNAP to the ladder.** Set `5.73 BPM` (`EVERY` reads
      `5.24s`), then tap `EVERY −` three times: `5.2s`, `5.15s`, `5.1s`. Landing
      on a round tenth from an off-ladder value is the whole point of this.
- [ ] The default cadence counts right against a clock: at `EVERY 5s`,
      one buzz per five seconds, twelve per minute.
- [ ] Tap steps once per tap on all four rows, `BPM` included; hold repeats
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

## 2. Finalise the version, then build the artifacts

The order matters, and §1 sits **inside** it: a dev version cannot be packaged
(`package` refuses three segments, ADR-0039), and a finalised one has to be
worn before it is bundled.

```
just release       # 1.3.12 -> 1.4, unit suite green. Builds nothing.
just deploy-nobump # sideload THAT build -- a bump would verify a number nobody ships
                   # ... now walk section 1 on the watch ...
just input-test    # the real-input checks, on a machine you are not also using
just icons         # regenerates publish/store-icon-500.png + launcher icon
just shot-release  # the screen a Store install shows -- the title is on it now
just package       # publish/Candle.iq -- signed release, and prints the form version
```

`just release` stops after the version because the wrist pass cannot be
automated; it prints these commands rather than running them. If §1 fails, fix
it and sideload with plain `just deploy` (which iterates to `1.4.1` and leaves
`1.4` free), then `just release -SetVersion 1.4` when it is clean.

Screenshots for the listing: `shots/vivoactive5.png` from `just shot-release`
(crop the round screen out of the simulator bezel capture).

**Check the values in that capture before you use it, and reset them properly.**
A listing screenshot has to show the defaults a new install starts on —
`POWER 20%`, `PULSE 100ms`, `EVERY 5s`, `6 BPM` — and by default it will not.

The simulator persists app Storage **keyed by the app UUID in `manifest.xml`**,
not by the PRG name. That UUID has never changed, so every build shares one
store: the unit tests, the debug sideload and the release capture all read and
write the same values, and the file is still named from the Pacer era. The
2026-08-29 capture read `POWER 100%` / `PULSE 240ms` for exactly this reason —
values a test sweep left behind, in a file called `PACER-VIVOACTIVE5-TEST.DAT`.

Do not tap the values back. **Delete the store and re-shoot**, which is the only
way to photograph a genuinely fresh install:

```
Remove-Item "$env:TEMP\com.garmin.connectiq\GARMIN\APPS\DATA\*.DAT", `
            "$env:TEMP\com.garmin.connectiq\GARMIN\APPS\DATA\*.IDX"
just shot-release
```

The simulator must not be running. It recreates the store on the next launch,
and the app falls back to `DEFAULT_*` in `candleApp.mc` — which is what a
stranger's watch does on first launch, so this is the honest picture.

## 3. The store form

**The copy lives in `store-listing.md` — paste from there, not from here.**
Every field and the full description are in that one file, so the listing has a
single home that changes when the app does. What follows is only what the *form*
needs that the copy cannot carry.

- **On-device name** is not a form field. It stays **Candle**, and it comes from
  the manifest's `AppName` resource.
- **Version** is a free-text box: type **whatever `just package` printed**. The
  manifest has no app-version field, so nothing but a person typing correctly
  keeps the listing and the glass in agreement (ADR-0037, ADR-0039).
- **Icon** is `publish/store-icon-500.png` (500×500 sRGB, ~10 px padding), from
  `just icons`.
- **Permissions**: none. `<iq:permissions/>` is empty; say so if asked.

**Read the top of `store-listing.md` before editing a word of the description.**
It records the rule the copy is written under — Garmin's Medical Apps guideline,
which requires regulatory documentation for any app whose description indicates
use in treating or preventing a condition. Candle is a metronome and is
described as one. A sentence about what resonance breathing *does to a body* is
the sentence that turns a 72-hour review into a rejection.

## 4. After approval

- [ ] Install from the store on a clean watch (or after uninstalling the
      sideload — note: uninstalling wipes stored settings; same-key signed
      store install over the sideload upgrades in place instead).
- [ ] Launcher name and icon are Candle's.
- [ ] Main screen's bottom line is the battery (or `VIBE OFF`). The settings
      screen shows the title **`Candle v1.0` at the top** — it is drawn in
      release builds too (ADR-0037) — and NOTHING along the bottom, which is
      the exit hint's band and only speaks for two seconds after a Back
      (ADR-0036).
- [ ] **The version on the glass matches the store listing exactly.** They are
      the same string by construction: the number typed into the upload form is
      whatever `APP_VERSION` said at `just package` time. If they differ, the
      bundle that was uploaded is not the one that was packaged.
- [ ] The Connect IQ phone app reports the same version.
- [ ] Tag the repo with the released version and update the README's store
      link.
