# AGENTS.md — Pacer (Garmin Connect IQ, vívoactive 5)

Pacer is a Monkey C **watch-app** that vibrates twice per breathing cycle to pace
resonance-frequency breathing. Single target device.

---

## THREE DESIGN DECISIONS THAT LOOK LIKE BUGS. DO NOT "FIX" THEM.

**1. The cue is haptic. There is never a visual breathing indicator.** No
animated arc, no pulsing ring, no phase readout. The app exists to pace breathing
*without* looking at the watch, so a visual cue would invite exactly the
attention it is meant to free. A screen that does not change between pulses is
the intended design, not a gap.

There is exactly one other thing on the screen that reacts to state, and it is
not a cue either: the bottom line reads `VIBE OFF` when the watch cannot
vibrate. That reports whether the app can do its job at all, in the same slot the
build version occupies — it does not change between pulses, carries no phase and
says nothing about breathing. It is the only warning that belongs there. A future
agent will read rule 1 and want to delete it; do not.

The clock at the top is not an exception to that rule either — it tracks the wall
clock, not the breath. It is the only thing on screen that changes on its own, and the
only reason `timerCallback` requests a redraw at all: it requests one *only* when
the displayed minute changes, so a session repaints about once a minute rather
than eleven times. Every other change requests its own update.

That gating is also why the cue timer carries the clock instead of a second timer
running beside it. A free-running 60 s timer would drift up to a full minute
behind the wall clock; hanging the check on the cue keeps the displayed minute at
most one cue interval (~5 s) stale for no extra timer at all.

Deleting the clock has been proposed once already, on the argument that it does
no job the app needs and costs a repaint a minute for nothing. Reading the time
without breaking off a breathing session *is* the job, and one repaint a minute
is what it costs. It stays.

**2. The two cues per breath are identical, and carry no phase information.**
What the wrist feels is a metronome at twice the breath rate; nothing in it
distinguishes "inhale now" from "exhale now".

This is correct because inhale and exhale are the same length — an equal I:E
ratio, chosen deliberately, on the grounds that there is no good evidence 4:6 or
1:2 does anything measurable. Equal phases make the two boundaries
interchangeable, so there is no wrong beat to start on and inverted phase is the
identical practice.

What that buys is **free re-entry**: distraction, a notification buzz, a missed
pulse, even the timer restarting mid-session when the pace is nudged — every
disturbance costs exactly one breath and resolves itself on the next cue, with
nothing to count and no way to be wrong.

An agent reviewing this app will be tempted to encode the phase (one pulse in,
two pulses out) — `Attention.vibrate` takes up to 8 `VibeProfile`s, so it is
nearly free to build. **It has already been proposed once and was wrong.** It
would trade the self-healing property away to fix a problem that only exists
under an asymmetric ratio this app does not use. If the I:E ratio ever stops
being 1:1, revisit this; until then the identical cue is load-bearing.

**3. Pacer builds nothing the watch or another app already does.** It is a
metronome for the wrist and nothing else. Where a capability already exists
outside the app, Pacer delegates to it rather than growing its own copy.

Two things follow from that, both of which read as missing features:

- **Palm safety is the watch's Lock Screen**, not an app-level touch lock. See
  the section below for what reimplementing it cost.
- **There is no session timer.** No duration setting, no elapsed-time display, no
  auto-stop, no start button. Someone who wants a time-bound session runs a timer
  app alongside Pacer, which the watch does perfectly well already.

The test for any proposed feature is: does the watch, or an app the user can run
in parallel, already do this? If yes, it does not belong here. Adding it would
buy a little convenience for a permanent increase in the surface that can break —
and the touch lock is the standing proof of how that trade goes. It was a real
feature, correctly motivated, and it could leave the whole watch needing a
reboot.

---

## THE MANDATORY LOOP

```
edit  →  just build  →  just test  →  iterate
```

**Nothing is done until both pass.** Not "should work", not "compiles cleanly in
my head". `just build` exits 0 at strict typecheck AND `just test` reports all
tests passing, or the work is not finished.

---

## HARD RULE: confirm every API in ./sdk-docs before using it

`./sdk-docs` is a junction into the **installed, version-matched** SDK
documentation. Before calling any Toybox API:

1. Confirm the symbol exists.
2. Confirm its exact signature and its **Since: API Level**.
3. Confirm the API level is **≤ 5.2.0** (see device facts below).

**Never infer an API from another language, from a similar-sounding name, or
from memory.** Monkey C looks like several other languages and is none of them.

Two things this project learned the hard way — both are why you verify by
compiling, not just by reading:

- **The HTML docs are not always right.** `WatchUi.PickerFactory.getDrawable` is
  documented as returning `Drawable`, but the compiled API requires
  `Drawable?`. Overriding with the documented type fails at `-l 3`.
- **Existing ≠ callable in context.** `Graphics.getFontHeight` exists and is
  documented, but raises *"Invalid Font Specified"* when called from the unit
  test runner, because there is no graphics context. To measure text in a test,
  get a real `Dc` from `Graphics.createBufferedBitmap({...}).get().getDc()`.

### Docs lookup order

1. **`./sdk-docs`** — ALL API questions. Authoritative, version-matched. Never skip.
2. **`./sdk-samples`** — 42 working sample apps. `Picker`, `Menu2Sample`,
   `ApplicationStorage`, `Attention`, `Timer` are the relevant ones here.
3. **Context7** (`/websites/developer_garmin_connect-iq`) — guide-level prose
   only: Core Topics, UX guidelines, FAQ. **NOT** a source for API signatures or
   API levels.
4. **WebFetch developer.garmin.com** — last resort. Most flag/API pages are
   JS-rendered and return only nav chrome.

The SDK root also ships local HTML guides (`CoreTopics.html`, `FAQ.html`,
`UserExperienceGuidelines.html`) — version-matched, so prefer them over Context7
when they cover the question.

**No embeddings, no vector DB, no RAG layer.** Grep over `./sdk-docs` is the
retrieval strategy. Both junctions are gitignored.

---

## Device facts (read from the SDK, not guessed)

Source: `%APPDATA%\Garmin\ConnectIQ\Devices\vivoactive5\compiler.json`

| Fact | Value |
|---|---|
| Device id | `vivoactive5` |
| API level | **5.2.0** — do not use APIs above this |
| Part number | `006-B4426-00` |
| Resolution | **390 × 390**, round, AMOLED, 16 bpp |
| Device family | `round-390x390` |
| **watchApp memory budget** | **786,432 bytes (768 KB)** |
| glance / background budget | 65,536 bytes (64 KB) each |
| Code page size | 4096 |

Measured font heights on this device: `FONT_MEDIUM` 54 px, `FONT_SMALL` 48 px.
These are large relative to the screen — a common source of overlap bugs.

`minApiLevel` in `manifest.xml` stays at `3.0.0`. It is a store-compatibility
floor, not a feature gate; raising it grants no APIs. The number that governs
your code is **5.2.0**.

---

## Input: the measured event chain (do not re-derive this)

Established by driving real input into the simulator with `tools/input.ps1` and
reading the app's own trace. **Observed, not inferred:**

| Input | Events, in order |
|---|---|
| tap | `onSelect`, **then** `onTap` |
| press enter (upper) | `onKeyPressed(4)`, `onSelect`, `onKey(4)`, `onKeyReleased(4)` |
| press esc (lower) | `onKeyPressed(5)`, `onBack`, `onKeyReleased(5)` |
| hold menu (lower, held) | `onKeyPressed(5)`, `onMenu`, `onKey(7)`, `onKeyReleased(5)` |
| swipe right | `onBack` — **no `onSwipe` at all** |
| swipe left | nothing |
| swipe up | `onNextPage`, `onSwipe(0)` |
| swipe down | `onPreviousPage`, `onSwipe(2)` |

`KEY_ENTER=4`, `KEY_ESC=5`, `KEY_MENU=7`. The lower button is **one** physical
button: pressed it is Back, held it is Menu.

Three traps, each of which produced a wrong implementation before being measured:

1. **`onSelect` fires BEFORE `onTap`.** Consuming `onTap` cannot suppress a tap.
2. **A right-swipe never raises `onSwipe`.** Filtering `SWIPE_RIGHT` there is
   dead code — it arrives only as `onBack`, indistinguishable at that level from
   the lower physical button.
3. A tap and the upper button both raise `onSelect`; a right-swipe and the lower
   button both raise `onBack`. **A behaviour event alone cannot tell touch from
   button.**

## Palm safety belongs to the watch, not to Pacer

**Never call `WatchUi.configureTouchEvents`.** Pacer used to, and it is the only
thing this project ever did that could damage the watch.

The problem is real: covering much of the screen with skin triggers a
platform-level exit that never reaches the delegate, which would end a session
silently. `configureTouchEvents({ :enabled => false })` suppresses it. But that
setting is **watch-global and outlives the app**, restoring it is fallible — the
simulator rejects `:enabled => true` every single time — and a leak leaves the
whole watch untouchable until it is rebooted. That happened repeatedly on the
wrist, and Pacer could not even repair it, because relaunching Pacer to run the
restore requires touch to reach the app list.

The vívoactive 5 already ships the feature: **hold the upper button → controls →
Lock Screen.** Confirmed on the wrist, and better than the app's version in every
respect:

- It works inside a running app, Pacer included.
- It locks the **buttons as well as the touchscreen**, so a stray lower-button
  press cannot end a session either — protection the app-level lock never had.
- The OS owns the state and restores it, so there is nothing to leak and no
  reboot to recover from. Worst case is now a lost session, not a bricked watch.

So Pacer holds no touch state at all. What that deleted: `TouchControl.mc`,
`_touchLocked`, `isTouchLocked`, `setTouchLocked`, `applyTouchLock`, the dimmed
rendering of the controls, the lock branches in `onSelect` and `onTap`, and three
lifecycle callbacks that existed only to restore touch — `pacerView.onShow`,
`pacerView.onHide` and `pacerApp.onInactive`.

**The exit rule is now one line with no condition: Back exits.** It was
conditional only because Pacer had a global setting to restore first. Two earlier
versions derived that condition the hard way — a four-second two-press
confirmation with an `armed`/`requested`/`restored` triple and two timers, then a
single check of the lock flag. Both are gone with the thing that required them.

The upper button lost its only job and now does nothing; it is still consumed so
a press cannot fall through. Holding it opens the controls menu, which never
reaches the app and is where Lock Screen lives.

**The fallback discriminator:** `onKeyPressed` fires for physical buttons and
*never* for gestures, always immediately before the behaviour. `pacerDelegate`
latches the last key press and consumes it inside the behaviour handler. This
preserves lower-button Back if touch configuration ever fails. Do not replace
this with `onTap` filtering.

Gesture thresholds live in the device config: swipeRight only counts as Back
when it starts within `maxDistToEdge` (81px) of the edge, travels more than
`minSwipeDeltaX` (78px), and finishes inside `maxSwipeDuration` (250ms).

`just input-test` confirms that taps reach the right control, that swipes and the
upper button are swallowed, and that the lower button really does close the app —
it asserts the process is gone afterwards, not just that a trace line appeared.
It is separate from `just test` because it needs a simulator window and
synthesises system-wide mouse events (it steals the pointer for ~40s).

Order matters in that script for one reason now: **Back closes the app, so its
check must be last** and nothing may follow it but the process check. The script
used to need a second throwaway instance for that, because the app-level lock had
to survive the earlier checks; with the lock gone, one launch does the whole run.

## Round screen: the bounding box is not the screen

The display is a **circle**. Text that fits within 390 px of width still gets
clipped near the top and bottom, where the usable chord is far narrower. At the
bottom of the version line's glyph box (y≈353) the usable width is ~228 px, not
390; another 13 px lower it is ~190 px. This is why the clock is centred in the
band above the first row instead of pinned near the top edge — at y=12 it would
have had ~134 px for the largest font on the screen, against ~176 px at y=21.

`source/Layout.mc` models this with `halfChordAt()` and `fitsOnRoundScreen()`.
**All layout coordinates must come from `Layout`.** Do not put literal pixel
offsets in `pacerView.mc` — that is exactly the bug the tests exist to catch.

**The same rule applies to strings, via `source/Display.mc`.** A fit test can
only be trusted if it measures the string the view actually draws. The layout
test spent several commits asserting that `"v0.22  UNLOCKED"` fit, on a screen
that had been drawing `"v0.22  EDIT"` the whole time — green, and measuring
nothing. Both of those strings are gone now — the lock state was being spelled
out in words on two lines while the row controls were already showing it by
dimming — but the rule they cost is permanent. `Display` holds the captions and
`PacerMath.format*`/`ClockText.formatTime` hold the value strings; `pacerView`
and `LayoutTest` both read from there, so the two cannot diverge.

**Captions are display strings and nothing else, and two of the three no longer
match the code under them.** The rows read `POWER` over
`_vibeStrength`/`vibrationStrength` and `BUZZ` over
`_vibeDuration`/`vibrationDuration`. A caption can be re-worded in `Display.mc`
alone; a **storage key cannot be re-worded at all**, because it is on the watch's
disk and renaming it silently resets that setting on every watch running Pacer.
The same holds for `paceHundredths` under the `PACE` row.

The `PACE` value is `5.71bpm | 5.25s` — the pace leads, being what a tap moves
and what assessment protocols are written in, with the cue interval past the
divider because that is the half you can check against a clock. Each number sits
against its own unit with no space, so the line splits at the divider rather than
at four separate gaps. Both numbers drop trailing zeros, so 6.00 renders
`6bpm | 5s` and the line changes width as it is tapped through.

## Row order lives in two places and they must agree

The screen is **POWER, PACE, BUZZ**, which is not the order the settings were
built in. That order is written down twice:

- the `ACTION_` constants in `Layout.mc`, because `editorActionAt` encodes its
  result as `(row * 2) + direction`, and
- the three `drawEditorRow` calls in `pacerView.mc`.

`pacerDelegate` dispatches on the constants **by name**, so it needs no edit when
the order changes — which is exactly what makes this dangerous. If the two lists
disagree, everything still compiles, every test that does not check the mapping
still passes, and every tap silently edits a different setting than the one under
the thumb. `editorLayoutMapsEveryControl` is the test that catches it, and
`tests/input-behaviour.ps1` is the one that proves it against real taps.

## The second width budget: the chord is not the only thing a row runs out of

An editor row has a circle parked at each end, and its label and value are
centred between them. **A line that fits the chord can still be drawn straight
through both controls** — the rows sit near the vertical centre, where the glass
is at its widest and the chord check is at its most forgiving, so that check
cannot see this collision at all.

Measured, not argued: `"5.22 sec (5.75 bpm)"` is **239 px** in `FONT_XTINY`
against the **232 px** between the two circles. It passed every fit test on the
screen and overlapped both controls, which is how `sec` became `s` and the line
came down to 204 px.

`Layout.editorTextMaxWidth()` is that budget — the gap between the controls less
a 10 px gutter each side, 212 px on this device — and
`layoutEveryReachableValueFits` now checks **both** budgets for every reachable
value, labels included. Any new caption or value format has to clear it, and the
`PACE` row is the one with the least room to spare, at its widest with two
decimals in both halves: `"5.71bpm | 5.25s"`. Trailing-zero trimming only ever
shortens it, so that is the worst case the sweep has to clear.

Coverage is exhaustive rather than sampled. That same sweep walks **every** value
the tap controls can reach (all 251 paces, 99 strengths, 241 lengths) and
`layoutEveryClockMinuteFits` every minute of the day in both clock formats,
rather than a hand-picked worst case. `layoutDisplayWidthMatchesTheDevice` pins
`Layout.DISPLAY_WIDTH` — which `pacerDelegate` maps taps with — to
`System.getDeviceSettings().screenWidth`, which is what `pacerView` draws with.

---

## Toolchain (pinned)

| Thing | Value |
|---|---|
| SDK | **9.2.0** at `%APPDATA%\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\` |
| JDK | Temurin **21.0.12+8** at `%USERPROFILE%\.jdks\jdk-21.0.12+8` (`JAVA_HOME`) |
| SDK manager | `connect-iq-sdk-manager` v0.8.4 at `%USERPROFILE%\bin` |
| **Developer key** | `%USERPROFILE%\.garmin-keys\developer_key.der`, referenced **only** via `$env:GARMIN_DEVELOPER_KEY` |
| Task runner | `just` 1.57.0 |

The key is **machine-level and shared by every Connect IQ app**. It is never
project-local and never in the repo (`*.der`/`*.pem` are gitignored). Losing it
means Store updates for anything signed with it become impossible.

Machine setup for a new machine: `~/bin/garmin-bootstrap.ps1` (one command,
idempotent, no admin needed). It prints the two steps that cannot be scripted:
accepting the SDK licence and the Garmin SSO login.

**Device configs must be pulled with `--include-fonts`.** Without it the
simulator dies with `can't open file ...\Fonts\FNT_*.cft` the moment it draws
text:
```
connect-iq-sdk-manager device download --manifest manifest.xml --include-fonts
```
Three `bitstreamVeraSans` fonts cannot be fetched by the CLI (spaces in the
name). They have not caused a problem so far.

---

## Commands

| Command | What it does |
|---|---|
| `just build` | Compile vivoactive5, `-w -l 3` (strict) |
| `just all-devices` | Compile every product in `manifest.xml` |
| `just test` | Build with `-t`, run in simulator, parse results, **non-zero exit on failure** |
| `just input-test` | Drive real taps/swipes/button presses into the simulator and assert which handler fires (~40s, steals the pointer) |
| `just test test_name=foo` | Run a single test |
| `just sim` | Launch simulator and load the app |
| `just shot` | Run in sim, capture window → `shots/vivoactive5.png` |
| `just shot-release` | Same, but of the **release** build (`-r`) — the only way to see `(:release)` code |
| `just deploy` | Bump version, build, push to watch over MTP |
| `just deploy-nobump` | Same without bumping |
| `just link-docs` | Re-point `sdk-docs`/`sdk-samples` after an SDK change |
| `just clean` | Remove `bin/` and `shots/` |

**`just` arguments are POSITIONAL, not `name=value`.** `just test test_name=foo`
silently passes the whole string `test_name=foo` as the *device* and fails with
"not in manifest.xml". Correct forms:

```
just build vivoactive5 1                    # device, typecheck
just test  vivoactive5 3 pacerMathIntervalAtDefaultPace
pwsh -File tools/test.ps1 -TestName pacerMathIntervalAtDefaultPace   # clearer
```

### A live simulator blocks the calling shell

The simulator and `monkeydo` both outlive their work and neither exits on its
own. **While either is alive, the shell that started it does not return** — so a
recipe looks like it has hung long after its real work finished. Measured:
`just shot` sat for **218 s** with the PNG already on disk, and returned the
instant the simulator was killed. With teardown it takes **~15 s**; `just test`
went from the same hang to **~9 s**.

Launch flags do not fix this, and one plausible-looking fix makes it worse:
adding `-RedirectStandardOutput` forces `UseShellExecute` off, so the child
*inherits* the shell's handles. The rule that works is simply **whoever starts
the simulator stops it**. `tools/env.ps1` provides `Start-SimulatorIfNeeded`,
`Stop-Simulator` and `Stop-MonkeyDo`; `shot`/`test` tear down, `just sim` is the
interactive exception. Use `just shot-keep` to keep the window — and expect that
command not to return until you close it.

### Verified flags — do not change these from memory

From `monkeyc --help` on SDK 9.2.0:
- `-d` device · `-f` jungles · `-o` output · `-y` private key
- `-w` warnings · `-l` typecheck **[0=off, 1=gradual, 2=informative, 3=strict]**
- `-t` / `--unit-test` compile unit tests in · `-r` release · `-e` package app

`monkeydo` on **Windows** uses **`/t`**, not `-t`:
```
monkeydo.bat <prg> <device_id> [/n] [/a file] [/t | /t test_name]
```
`monkeydo.bat` literally matches `IF "%~3"=="/t"` and falls through to its usage
banner for anything else. `device_id` is required.

---

## Deploy: MTP, and it CANNOT be verified from the host

The vívoactive 5 is a **Windows Portable Device (MTP)**. Verified:
`Get-PnpDevice -Class WPD` → `USB\VID_091E&PID_514A`, and it **never gets a
drive letter**. `Copy-Item` to `E:\GARMIN\APPS` cannot work. `tools/deploy.ps1`
uses the `Shell.Application` COM namespace instead.

> **Deploy CANNOT be verified by reading the file back. Never claim that it can.**

What was actually observed on a real deploy (v0.14):

- Before the copy, `GARMIN\APPS` held only `TEMP LOGS DATA SETTINGS MAIL OUT.BIN`
  — **no `.prg` at all**, despite Pacer being installed on the watch.
- Straight after `CopyHere`, `pacer.prg` **does** appear in the listing.
- The shell reports `Size=0` for it — but it reports `Size=0` for `OUT.BIN` too,
  so sizes are simply not exposed over MTP. A visible name proves an entry
  exists and nothing about whether the bytes arrived intact.
- Once the firmware installs the app the entry disappears again, which is why
  the directory looks empty between deploys.

So the listing is worthless as verification in both directions. The **only**
proof a deploy landed: launch Pacer on the watch and read the version off the
main screen. That is why `just deploy` bumps `APP_VERSION` in
`source/pacerApp.mc` before every build. If the watch shows an older version, it
is still running the old build.

**The version is drawn in debug builds only**, behind `Display.showsBuildVersion`
— a Store install has the Connect IQ app to report its version, so drawing it
there is the duplication the delegation rule rejects. This is safe precisely
because `deploy.ps1` calls `build.ps1` **without** `-Release`: every sideload is
a debug build, so the one workflow that cannot verify itself is the one that
keeps the version. If a release flag is ever added to the deploy path, this
verification loop dies silently — the watch would simply stop showing a version
and every deploy would look identical.

Unit tests compile with `-t`, which is a debug build, so **tests cannot see
`(:release)` code at all**. That is why `bottomLine` takes the flag as an
argument and only a one-line predicate is annotated, and why `just shot-release`
exists. Verified both ways: the release build draws no version, the debug build
draws `v0.22`.

A differently-signed build with the same app id must be uninstalled from the
watch first — and that wipes its stored pace/strength/duration settings.

---

## Reviewing shots/*.png

`just shot` writes `shots/<device>.png` — the whole simulator window, watch
bezel included. When reviewing:

1. **Clipping at the left/right edges.** On a round screen this means the text is
   wider than the chord at that height. If you see it, `Layout` said it would
   fit and the test is wrong, or the code bypassed `Layout`.
2. **Overlapping lines.** Anchors closer together than the font height. Compare
   the gap against the measured heights above (54/48 px).
3. **Vertical crowding at the poles.** The top and bottom of a round display have
   very little usable width.
4. Read the memory figure in the simulator status bar against the 768 KB budget.

A screenshot is confirmation, **not** the debugging loop. If a layout question can
be answered by a pure function in `Layout.mc`, write the test instead.

---

## Testing

Tests live in `tests/`, wired via `base.sourcePath = source;tests` in
`monkey.jungle`. They are compiled in only with `-t`, so they cost nothing in a
normal build (106.5 KB vs 132.3 KB).

One file per thing under test, and no more: `LayoutTest` (geometry, round-screen
fit, and tap hit mapping), `PacerMathTest` (clamping, pace arithmetic,
formatting), `ClockTextTest` (both clock formats), `MainInputGateTest`
(button-vs-touch, and the unlocked-start invariant), `SettingsTest`,
`input-behaviour.ps1`.

- Mark tests `(:test)`; they take a `Test.Logger` and return `Boolean`.
- Non-global test methods must be **static**.
- Asserts available: `assert`, `assertMessage`, `assertEqual`,
  `assertEqualMessage`, `assertNotEqual`, `assertNotEqualMessage`.
  (The SDK's own prose table for these is garbled — the method list is correct.)
- Put logic in pure modules (`Layout`, `PacerMath`) so it is testable without a
  running app instance.
- **Two tests write to Storage, and nothing else may** —
  `settingsStepsWalkEveryRangeEndToEnd`, because walking the real setters is the
  only way to prove they clamp, and `settingsVibeProfileTracksSettingChanges`,
  because the `VibeProfile` the motor is handed can only be reached through those
  same setters. Both restore from a `finally`, not from the end of the happy
  path: an assertion throws, and a restore that only runs on success strands
  whatever value the test died on in the simulator for every run after it. That
  is not hypothetical; it happened. Keep new tests pure.

**Do not weaken a test to make the loop green.** A failing test that reflects
reality is the tool working.

`base.sourcePath` must list `source;tests` explicitly. The self-referencing form
`$(base.sourcePath);tests` expands to the project root and drags the gitignored
`sdk-samples` junction into the build.

---

## What cannot be tested from here — needs your wrist

- **`Attention.vibrate` does nothing observable in the simulator.** Verification
  stops at the call: `settingsVibeProfileTracksSettingChanges` proves the right
  `VibeProfile` and the right timer period reach it after every setting change,
  and that both mechanisms fail loudly when broken — the cache invalidation and
  the pace restart were each deleted in turn and the test caught both. What the
  motor then does with that profile is only verifiable on a wrist.

  Two consequences worth knowing there. A **pace** change restarts the timer, so
  the next cue is a full new interval away and the phase resets — one breath, by
  design. A **strength or length** change does not: it lands on the next cue,
  which can be up to ~6.7 s later, so a tap will not alter a buzz already in
  flight.

- **A watch with vibration switched off feels identical to a broken app.** This
  is the one failure mode the app can see, so as of v0.23 it says so: the bottom
  line reads `v0.23  VIBE OFF` when `Attention has :vibrate` is false or
  `System.getDeviceSettings().vibrateOn` is off. If nothing is felt on the wrist
  and that warning is absent, the fault is below the app and no amount of reading
  this code will find it.
- **Where the cue stops being felt.** The strength floor is 2% and the length
  floor 10 ms, both deliberately below what a body registers, so the bottom of
  each scale is findable rather than hidden. Only a wrist can say where it is.
- Whether 5.71 breaths/min actually feels right.
- Real memory pressure and battery cost.
- Whether a deploy landed (see above).

Confirmed on-wrist, so stop re-litigating it: the cue timer keeps running
correctly through a full session with the screen off and the arm down.
