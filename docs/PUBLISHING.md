# Publishing Candle to the Connect IQ Store

The submission is four artifacts — the `.iq` bundle, the 500 px icon, the
listing text, and screenshots — plus a wrist pass that proves the build being
shipped is the build that works. Everything reproducible is scripted; this
file is the order to run it in.

## 1. Wrist verification (before packaging anything)

One pass per watch you own. For a supported device you do not own, the pass is
the simulator's: `just test <id>` green, `just input-test <id>` green, and
`just shot <id>` / `just shot-settings <id>` looked at by a person (ADR-0047).
The list below is written for the vívoactive 5; on the Forerunner 955 "the
upper button" is START and "hold the lower button" is hold UP.

`just deploy` a debug build and confirm, on the watch:

- [ ] The launcher lists **Candle** with the candle icon.
- [ ] **`v<n>` along the BOTTOM of the settings screen** (upper button) matches
      what deploy printed — the ONLY proof a sideload landed, since MTP cannot
      be verified from the host. The main screen does not show it. It is drawn
      in release builds too (ADR-0037), so this line also checks what a Store
      install will show.
- [ ] **The candle mark is at the TOP of the settings screen**, and the two
      bands balance — a small thing at each end with the rows between
      (ADR-0040). It is the launcher icon, at the launcher's size.
- [ ] **The upper button is the ONLY way between the screens** — it opens the
      settings screen and the same press closes it. Neither ends the session;
      the cue keeps arriving throughout. There is no `BACK` button any more
      (ADR-0036).
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
just release       # 1.3.12 -> 1.4, the suite green on EVERY product. Builds nothing.
just deploy-nobump # sideload THAT build -- a bump would verify a number nobody ships
                   # ... now walk section 1 on the watch ...
just input-test    # the real-input checks, on a machine you are not also using
just input-test fr955      # the same on the other device -- its wrist pass is the simulator's
just icons         # regenerates publish/store-icon-500.png + every launcher icon
just shot-release  # main screen, as a Store install draws it
just shot-settings # settings screen -- takes the pointer for a moment
just shot fr955; just shot-settings fr955   # look at both screens on the other glass
just store-shots   # -> publish/store-shot-*.png, square 500x500 for the listing
just package       # publish/Candle.iq -- signed release, every device, prints the form version
```

Both shots are RELEASE builds, which is the only way to see what a stranger
gets: unit tests compile with `-t`, so anything behind a `(:release)`
annotation is invisible to them. `shot-settings` presses the upper button to
get there, because nothing on the glass navigates (ADR-0036).

`just release` stops after the version because the wrist pass cannot be
automated; it prints these commands rather than running them. If §1 fails, fix
it and sideload with plain `just deploy` (which iterates to `1.4.1` and leaves
`1.4` free), then `just release -SetVersion 1.4` when it is clean.

Screenshots for the listing. `just shot-release` and `just shot-settings` write
raw simulator-window captures to `shots/`; **`just store-shots` turns them into
the images you upload**, in `publish/`:

| upload order | file | shows |
| --- | --- | --- |
| 1 | `publish/store-shot-1-main.png` | clock, `POWER`, `BUZZ`, battery |
| 2 | `publish/store-shot-2-settings.png` | candle mark, `EVERY 5s`, `6 BPM`, version |

**Upload the main screen first** — it is the one shown in the store's app list,
where the settings screen would read as an unexplained pair of numbers.

### What the store wants from an image

Garmin's submission page does not publish image specs. These are observed, from
the developer forums and from what the upload form accepts, so if a future
upload is rejected then the form's own message is better evidence than this
list — fix it here rather than working around it.

- **Square.** This is the one that actually bites: the store site stretches a
  non-square image into a square slot, which is why so many listings show an
  oval where a round watch should be.
- **500×500 px**, and no larger.
- **PNG, under ~150 KB** each. `store-shots` prints each size and warns past it.

Cropping this by eye is what the script exists to prevent. Two images framed
"about square, roughly centred" look fine one at a time and visibly mismatched
side by side in a listing — the script finds the watch by its widest contiguous
run against the white background, so both crops land at the same scale.

**Check the values in that capture before you use it, and reset them properly.**
A listing screenshot has to show the defaults a new install starts on —
`POWER 50%`, `BUZZ 50ms`, `EVERY 5s`, `6 BPM` — and by default it will not.

The simulator persists app Storage **keyed by the app UUID in `manifest.xml`**,
not by the PRG name. That UUID has never changed, so every build shares one
store: the unit tests, the debug sideload and the release capture all read and
write the same values, and the file is still named from the Pacer era. The
first release capture read maxed-out values for exactly this reason — a test
sweep's leftovers, in a file called `PACER-VIVOACTIVE5-TEST.DAT`.

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
      screen shows the candle mark at the top and **the version along the
      bottom** — drawn in release builds too (ADR-0037, ADR-0040) — with the
      exit hint taking that band for two seconds after a Back (ADR-0036).
- [ ] **The version on the glass matches the store listing exactly.** They are
      the same string by construction: the number typed into the upload form is
      whatever `APP_VERSION` said at `just package` time. If they differ, the
      bundle that was uploaded is not the one that was packaged.
- [ ] The Connect IQ phone app reports the same version.
- [ ] Tag the repo with the released version and update the README's store
      link.

## 5. Releasing an update

An update is the **same listing with a new bundle**. Three things must not
change, and each is a silent way to ship a second app instead of an update:

- **The app id** — the `id` attribute in `manifest.xml`. Never regenerate it.
- **The signing key** — the one at `GARMIN_DEVELOPER_KEY`. A bundle signed
  with any other key is a different app to the store, and on a watch it will
  not install over the existing one.
- **The name** — the on-device `AppName` resource. The store title is edited on
  the form, not here.

What changes: the `.iq`, the version string, the What's new text, and — when
the screens or the device list changed — the description and screenshots.

### The build side

1. Land the work. `just test-all` green, `just input-test` green on every
   device, shots looked at on every device.
2. `just release`. A version already in the store is left alone, so an update
   needs either a `just deploy` first (iterates to `1.0.1`, then `release`
   finalises to `1.1`) or `pwsh -File tools/release.ps1 -SetVersion 1.1`
   directly. Either way the suite runs on every product before the version
   moves.
3. `just deploy-nobump`, walk §1 on the wrist; `just input-test <id>` and the
   shots stand in for a device you do not own.
4. `just icons`, `just shot-release`, `just shot-settings`, `just store-shots`,
   `just package`. The screenshots only need regenerating if a screen changed;
   the store keeps one set per listing, not one per device.

### The store side

1. <https://apps.garmin.com/developer/dashboard>, signed in as the account that
   published 1.0. Open the app.
2. Choose the update action for the app (the dashboard labels it as uploading a
   new version; the page for the first submission was "Submit an App", and it
   is not that one). Upload `publish/Candle.iq`.
3. The form validates the bundle and lists **the devices it read from it**.
   Both watches must be there. If only one is, the bundle was packaged from a
   manifest with one product — stop and rebuild.
4. **Version**: type exactly what `just package` printed. The form refuses a
   version it has seen before ("The updated version should be different from
   previous versions"), and nothing but this box keeps the listing and the
   glass in agreement (ADR-0037, ADR-0039).
5. **What's new**: paste the line for this version from `store-listing.md`.
   Plain text only — a `<` or `>` in either box has been seen to fail the
   upload with a media-type error.
6. If the **description** changed, edit it now, from `store-listing.md`. For
   1.1 it did: the Controls bullets name both watches' buttons.
7. Submit. Garmin's own figure is up to 72 hours for review, longer over
   holidays. While it is pending the old version stays live, and the new one
   can be downloaded to your own watch from the dashboard.

### What to expect afterwards

- The dashboard and the public store page do not update in step: the new
  version can take minutes to hours to show on the page and in the Connect IQ
  phone app, and re-uploading in the meantime is refused as a duplicate
  version. Wait; do not re-upload.
- Wearers who left auto-update on (the default in the Connect IQ phone app)
  get 1.1 on their next sync; the rest see an update offered. A watch that was
  not supported before — the Forerunner 955 — sees Candle as a new app.
- A **beta** is not the way to test an update: Garmin's beta uploads need a
  separate app id and are only ever visible to your own account. To try an
  update before the world gets it, sideload the release build with
  `just deploy-nobump`, which is what §1 already is.
- Then §4, on the watch that already has 1.0 from the store: installing the
  update over it upgrades in place and keeps the stored settings, because the
  id and the key are the same. `v1.1` along the bottom of the settings screen
  is the proof, and it must match the listing.
