# AGENTS.md — Pacer (Garmin Connect IQ, vívoactive 5)

Pacer is a Monkey C **watch-app** that vibrates twice per breathing cycle to pace
resonance-frequency breathing. Single target device.

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

**The primary gate:** `pacerView.onShow()` disables touch globally through
`TouchControl`. This is mandatory: covering much of the screen with skin can
trigger a platform-level exit that never reaches the delegate, and only
`WatchUi.configureTouchEvents({ :enabled => false })` suppresses it. The API is
5.2.0 and supported on the vívoactive 5. **Do not remove this mechanism.**

The disabled setting can survive Pacer exiting and leave the whole watch
without touch until reboot. Restoring with `:enabled => true` is also fallible:
the simulator repeatedly returns `false`, even when called before navigation.
Therefore physical Back uses a four-second, two-press confirmation. The first
press immediately shows `Back again to exit`, then restores touch
asynchronously while the prompt is visible. The second press exits only after
`TouchControl` verifies the live setting; if cleanup is still pending, the app
exits from its callback once restoration succeeds. When cleanup fails or the
window expires, Pacer stays open and re-enables the palm-touch gate. The menu's
`System.exit()` path follows the same restore-before-exit rule. `onHide()`,
`onInactive()` and `onStop()` are best-effort restoration fallbacks, not
permission to exit with an unverified touch state.

**The fallback discriminator:** `onKeyPressed` fires for physical buttons and
*never* for gestures, always immediately before the behaviour. `pacerDelegate`
latches the last key press and consumes it inside the behaviour handler. This
preserves lower-button Back if touch configuration ever fails. Do not replace
this with `onTap` filtering.

Gesture thresholds live in the device config: swipeRight only counts as Back
when it starts within `maxDistToEdge` (81px) of the edge, travels more than
`minSwipeDeltaX` (78px), and finishes inside `maxSwipeDuration` (250ms).

`just input-test` confirms that touch is suppressed or safely consumed on the
main screen, physical buttons still work, the exit-confirmation window expires
safely, and rejected touch restoration does not strand the app. It is separate
from `just test` because it needs a simulator window and synthesises system-wide
mouse events (it steals the pointer for ~40s).

## Round screen: the bounding box is not the screen

The display is a **circle**. Text that fits within 390 px of width still gets
clipped near the top and bottom, where the usable chord is far narrower. At the
hint line (y≈366) the usable width is only ~190 px, not 390.

`source/Layout.mc` models this with `halfChordAt()` and `fitsOnRoundScreen()`.
**All layout coordinates must come from `Layout`.** Do not put literal pixel
offsets in `pacerView.mc` — that is exactly the bug the tests exist to catch.

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
normal build (115.8 KB vs 125.3 KB).

- Mark tests `(:test)`; they take a `Test.Logger` and return `Boolean`.
- Non-global test methods must be **static**.
- Asserts available: `assert`, `assertMessage`, `assertEqual`,
  `assertEqualMessage`, `assertNotEqual`, `assertNotEqualMessage`.
  (The SDK's own prose table for these is garbled — the method list is correct.)
- Put logic in pure modules (`Layout`, `PacerMath`) so it is testable without a
  running app instance.

**Do not weaken a test to make the loop green.** A failing test that reflects
reality is the tool working.

`base.sourcePath` must list `source;tests` explicitly. The self-referencing form
`$(base.sourcePath);tests` expands to the project root and drags the gitignored
`sdk-samples` junction into the build.

---

## What cannot be tested from here — needs your wrist

- Menu/picker interaction and whether values commit.
- **`Attention.vibrate` does nothing observable in the simulator.** Whether the
  pulses land at the right interval and strength is only verifiable on-device.
- Timer drift over minutes; whether 5.71 breaths/min actually feels right.
- Real memory pressure, battery cost, sleep/activity interaction.
- Whether a deploy landed (see above).
