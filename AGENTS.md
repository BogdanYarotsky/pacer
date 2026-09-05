# AGENTS.md — Candle (Garmin Connect IQ)

Candle is a Monkey C **watch-app** that vibrates twice per breathing cycle to
pace resonance-frequency breathing. Two target devices — the vívoactive 5 and
the Forerunner 955 — and one rule for adding the next (ADR-0047).

**This file is operational: how to build, what the hardware is, what the tools
do. Every design decision lives in [`docs/adr/`](docs/adr/README.md), one file
per decision, referenced from the code by id.**

**Read these four before changing anything** — they are the decisions that look
like bugs, and each has been "fixed" or proposed at least once:

- [ADR-0001](docs/adr/0001-haptic-only-no-visual-cue.md) — the cue is haptic;
  there is never a visual breathing indicator.
- [ADR-0002](docs/adr/0002-identical-cues-carry-no-phase.md) — the two cues per
  breath are identical and carry no phase.
- [ADR-0003](docs/adr/0003-delegate-never-rebuild.md) — Candle builds nothing
  the watch or another app already does.
- [ADR-0004](docs/adr/0004-palm-safety-is-the-watchs-lock-screen.md) — palm
  safety belongs to the watch's Lock Screen. `configureTouchEvents` is banned.

---

## THE MANDATORY LOOP

```
edit  →  just build  →  just test  →  iterate
```

**Nothing is done until both pass.** Not "should work", not "compiles cleanly in
my head". `just build` exits 0 at strict typecheck AND `just test` reports all
tests passing, or the work is not finished.

`just test` boots the simulator and is the expensive step. Two cheap checks come
first and catch most of what breaks:

```
just all-devices                                    # no simulator, every product
pwsh -File tools/build.ps1 -Device all -Typecheck 3 -UnitTest
```

The second one typechecks the **test** files, which a normal build does not
(ADR-0035). Compile both ways, fix everything, *then* run the simulator once.

**A change to `Layout`, a font, or a drawn string is not done until
`just test-all` is green.** The suite measures the glass and the fonts of the
device it runs on, so a green run on one watch says nothing about another
(ADR-0045). `just test` alone is the per-edit loop; `test-all` is the gate.

---

## Where prose lives, and the one rule about it

Rationale goes in an ADR. Hazards stay in the code. **Numbers a test can compute
go in neither** — see
[ADR-0033](docs/adr/0033-no-computed-numbers-in-prose.md), which is the rule
this repo most often broke.

`just check-adrs` runs inside `just test` and fails on a dangling `ADR-NNNN`
reference or an accepted ADR nothing points at.

### A tunable change touches exactly these, in this order

A checklist, so it is not a hunt. Ranges, steps, defaults and geometry
constants all follow it:

1. **The constant** — `candleApp` (ranges, steps, defaults) or `Layout`
   (geometry). Its ADR reference stays; there should be no arithmetic in the
   comment to update.
2. **`CandleMath`**, if a ladder or a formatter reads the unit.
3. **`tests/SettingsTest.mc`** — `settingsRangesAndStepsAreCoherent` pins
   *relationships*, never literals. If you are changing a literal there, the
   assertion was wrong to begin with.
4. **`tests/LayoutTest.mc`** — `rowRange` / `rowSweepStep` if a range moved. The
   sweeps then cover it automatically.
5. **`tests/CandleMathTest.mc`** — the fixed-point tables. These *are* literals,
   correctly: they are the conversion's specification.
6. **The ADR**, if the *reason* changed. If only the value changed, it did not.
7. **Docs, last and least.** README and PUBLISHING name rows and behaviours;
   they must not restate ranges and steps.

---

## HARD RULE: confirm every API in ./sdk-docs before using it

`./sdk-docs` is a junction into the **installed, version-matched** SDK
documentation. Before calling any Toybox API:

1. Confirm the symbol exists.
2. Confirm its exact signature and its **Since: API Level**.
3. Confirm the API level is **≤ 5.2.0**.

**Never infer an API from another language, from a similar-sounding name, or
from memory.** Monkey C looks like several other languages and is none of them.

Two things learned the hard way — both are why you verify by compiling:

- **The HTML docs are not always right.** `WatchUi.PickerFactory.getDrawable` is
  documented as returning `Drawable`, but the compiled API requires `Drawable?`.
  Overriding with the documented type fails at `-l 3`.
- **Existing ≠ callable in context.** `Graphics.getFontHeight` is documented but
  raises *"Invalid Font Specified"* from the unit test runner, because there is
  no graphics context. To measure text in a test, get a real `Dc` from
  `Graphics.createBufferedBitmap({...}).get().getDc()`.

### Docs lookup order

1. **`./sdk-docs`** — ALL API questions. Authoritative, version-matched. Never skip.
2. **`./sdk-samples`** — 42 working sample apps. `Picker`, `Menu2Sample`,
   `ApplicationStorage`, `Attention`, `Timer` are the relevant ones here.
3. **Context7** (`/websites/developer_garmin_connect-iq`) — guide-level prose
   only. **NOT** a source for API signatures or API levels.
4. **WebFetch developer.garmin.com** — last resort. Most pages are JS-rendered
   and return only nav chrome.

The SDK root also ships local HTML guides (`CoreTopics.html`, `FAQ.html`,
`UserExperienceGuidelines.html`) — version-matched, so prefer them over Context7.

**No embeddings, no vector DB, no RAG layer.** Grep over `./sdk-docs` is the
retrieval strategy. Both junctions are gitignored.

---

## Device facts (read from the SDK, not guessed)

Source: `%APPDATA%\Garmin\ConnectIQ\Devices\<id>\compiler.json` and
`simulator.json`. `just check-devices` prints the live table; this one is the
orientation.

| Fact | vívoactive 5 | Forerunner 955 / Solar |
|---|---|---|
| Device id | `vivoactive5` | `fr955` |
| API level | **5.2.0** — do not use APIs above this | **5.2.0** |
| Resolution | **390 × 390**, round, AMOLED, 16 bpp | **260 × 260**, round, MIP, 8 bpp |
| Device family | `round-390x390` | `round-260x260` |
| Launcher icon | 56 × 56 | 40 × 40 |
| **watchApp memory budget** | **786,432 bytes (768 KB)** | 786,432 bytes |
| glance / background budget | 65,536 bytes (64 KB) each | same |
| Buttons the app sees | Action (upper), Back (lower); Back held = menu | START (upper right), BACK (lower right), UP/DOWN (left); UP held = menu |

Measured font heights on the vívoactive 5: `FONT_XTINY` 32 px, `FONT_TINY`
41 px, `FONT_SMALL` 48 px, `FONT_MEDIUM` 54 px, `FONT_LARGE` 63 px. These are
large relative to the screen and are a common source of overlap bugs. The rows
are `FONT_XTINY` and it is not a free choice — at `FONT_TINY` the widest row
line would force the control radius down by roughly half (ADR-0012, ADR-0013).
On the Forerunner 955 the same fonts measure roughly in proportion to its
smaller glass — a measurement, not a rule the SDK makes — and `just test fr955`
logs the heights it finds. **Geometry is a proportion of the glass**
(ADR-0045): `Layout` carries one reference design, tuned on the vívoactive 5,
and scales it to whatever the `Dc` reports. Nothing in `source/` names a
resolution.

`minApiLevel` in `manifest.xml` stays at `3.0.0`. It is a store-compatibility
floor, not a feature gate; raising it grants no APIs. The number that governs
your code is the lowest API level among the products, **5.2.0** today.

Adding a device: product in `manifest.xml` → `connect-iq-sdk-manager device
download --manifest manifest.xml --include-fonts` → `just icons` →
`just test <id>`, `just input-test <id>`, `just shot <id>`,
`just shot-settings <id>`, and look at both. `just check-devices` refuses a
watch the app cannot be used on (ADR-0047).

---

## Repo map — where each concern lives

Two screens, one view class and one delegate class, each told which screen it
is. Every concern has exactly one home:

| Concern | Home | Decisions |
|---|---|---|
| What is on each screen, in what order | `Rows` | ADR-0028 |
| Geometry, round-screen chord maths, the scale to the glass | `Layout` | ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0045 |
| Which devices, their icons, what a new one must pass | `manifest.xml`, `tools/check-devices.ps1`, `tools/make-icons.ps1` | ADR-0046, ADR-0047 |
| Every drawn string | `Display` | ADR-0029 |
| State, persistence, the cue timer | `candleApp` | ADR-0018, ADR-0022, ADR-0025 |
| Cue arithmetic, ladders, formatting | `CandleMath` | ADR-0019, ADR-0021, ADR-0023 |
| Input decoding | `candleDelegate`, `MainInputGate` | ADR-0007, ADR-0008, ADR-0009, ADR-0010 |
| Build and verify | `just` → `tools/*.ps1` | ADR-0031, ADR-0034 |

**When prose and a test disagree, the test is right.**

### Couplings that break silently

- **Storage keys are on-disk API** — ADR-0025. A unit change is a new key.
- **The manifest id is the store identity**: never regenerate it. The manifest
  `entry` attribute must track the app class name in lockstep.
- **A setting reachable from no screen is still a live setting** — ADR-0028.
- **The jungle `sourcePath` stays literal** — ADR-0035.
- **`deploy.ps1` greps the app source for the version constant** and matches the
  staged `.prg` by name — a rename must update it in the same commit.

---

## What each button does, on each screen

Two rules, and the table below is only their consequences: **a press of the
upper-right button cycles the two screens, and a held MENU button exits from
either.** Nothing else navigates — no gesture, and nothing drawn on the glass.
ADR-0036

Which physical button carries each is the device's business (ADR-0047):

| | vívoactive 5 | Forerunner 955 |
|---|---|---|
| upper-right button → `onSelect` | Action (upper) | START |
| Back → `onBack` | the lower button, and a right swipe | BACK (lower right), and a right swipe |
| menu hold → `onMenu` | the lower button, held | UP (left middle), held |
| the watch's own controls menu (Lock lives there) | upper button, held | LIGHT, held |
| page turns → swallowed | vertical swipes | vertical swipes, and UP / DOWN pressed |

| | main screen | settings screen |
|---|---|---|
| upper-right button (press) | push the settings screen | pop back |
| the watch's controls menu | never reaches the app | same |
| Back (button press, or right swipe) | swallowed, shows `HOLD TO EXIT` | same |
| tap the bottom band | nothing — it holds the battery | nothing — it is inert |
| **menu button (held → Menu)** | **exit the app** | **exit the app** |

The two screens answer every input identically except the upper button, which is
the one that tells them apart. That is newer than it looks: the settings screen
swallowed a Back in silence and had a `BACK` button in its bottom band until
ADR-0036 noticed the upper button already went both ways.

Why Back is trusted with nothing: ADR-0008, ADR-0009. Why nothing is drawn to
replace it: ADR-0036. **Why the screens are custom at all rather than `Menu2`,
and what that decision cost: ADR-0044** — written after v1.0 shipped, from use
rather than prediction. It also records the one flaw that shipped knowingly: the
lower button's press does nothing and its hold quits, separated only by
duration, so a lingering thumb ends a session.

### Open, and NOT yet diagnosed: a queued upper-button press

Observed on the wrist, 2026-08-29. **Hold the upper button** to open the watch's
own controls menu, dismiss it, and come back to Candle — and the *next touch on
the glass* switches screens, as though the press were sitting in a queue waiting
to be delivered. It goes the other way too: the same thing happens returning to
the settings screen.

Nothing here is confirmed. The obvious reading is that the firmware delivers the
`KEY_ENTER` from the hold after the app regains focus, and `MainInputGate`
latches it, so the next `onSelect` — raised by a *tap*, which is the path that
normally has no key behind it (ADR-0007) — consumes a key it did not earn and
takes the screen change. That is a hypothesis with no measurement behind it.

Do not fix it from that paragraph. Start by getting the event chain out of a
real wrist session: `onKeyPressed`/`onKeyReleased`/`onSelect` traces across the
controls-menu round trip, which is a case ADR-0007's measurements never covered
because the app never lost focus in them. `MainInputGate.clear()` on resume is
the first thing to try once the chain is known, and `onShow` is where it would
go. Deferred deliberately until after the store submission.

---

## Toolchain (pinned)

| Thing | Value |
|---|---|
| SDK | **9.2.0** at `%APPDATA%\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\` |
| JDK | Temurin **21.0.12+8** at `%USERPROFILE%\.jdks\jdk-21.0.12+8` (`JAVA_HOME`) |
| SDK manager | `connect-iq-sdk-manager` v0.8.4 at `%USERPROFILE%\bin` |
| **Developer key** | `%USERPROFILE%\.garmin-keys\developer_key.der`, referenced **only** via `$env:GARMIN_DEVELOPER_KEY` |
| Task runner | `just` 1.57.0 |

The key is **machine-level and shared by every Connect IQ app**. Never
project-local, never in the repo (`*.der`/`*.pem` are gitignored). Losing it
makes Store updates for anything signed with it impossible.

### When Smart App Control blocks the SDK manager

`connect-iq-sdk-manager.exe` is unsigned and carries no reputation, so Windows
Smart App Control refuses to launch it: every `just` recipe dies at `env.ps1`
with *"An Application Control policy has blocked this file"*, and CodeIntegrity
logs event 3077. `monkeyc` itself is unaffected — only the manager is blocked.

Smart App Control **cannot be switched back on once it is off**, short of
reinstalling Windows, so turning it off to compile is a one-way door. Set
`CIQ_SDK_BIN` to the SDK's `bin` directory instead; `env.ps1` prefers it over the
manager and everything downstream only ever wanted that path.

```
$env:CIQ_SDK_BIN = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin"
```

The cost: the manager no longer arbitrates which SDK is active, so `CIQ_SDK_BIN`
must be re-pointed by hand after an SDK upgrade — the same edit `just link-docs`
needs.

New machine: `~/bin/garmin-bootstrap.ps1` (one command, idempotent, no admin).
It prints the two steps that cannot be scripted: accepting the SDK licence and
the Garmin SSO login.

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

Every recipe that takes a device takes it as its first argument (`just test
fr955`, `just shot fr955`); the default is `vivoactive5`.

| Command | What it does |
|---|---|
| `just build` | Compile the default device, `-w -l 3` (strict) |
| `just all-devices` | Compile every product in `manifest.xml` |
| `just test` | Check ADRs and devices, build with `-t`, run in simulator, **non-zero exit on failure** |
| `just test-all` | `just test` on every product, one simulator run each — the gate for any `Layout` change |
| `just check-adrs` | ADR reference integrity alone — no build, no simulator |
| `just check-devices` | Every product against what the app needs from a watch, and its icon at its own size (ADR-0047) |
| `just icons` | The store icon, and one launcher icon per product at the size its config declares (ADR-0046) |
| `just input-test` | Drive real taps/swipes/presses into both screens and assert which handler fires (steals the pointer). Aims by the geometry the app prints, so it works on any device |
| `just sim` | Launch simulator and load the app |
| `just shot` | Run in sim, capture window → `shots/<device>.png` |
| `just shot-release` | Same, of the **release** build — the only way to see `(:release)` code (ADR-0031) |
| `just shot-settings` | Release build's **settings** screen → `shots/<device>-settings.png`. Presses the upper button to get there, so it takes the pointer briefly |
| `just deploy` | Bump the **iteration**, build, push to watch over MTP |
| `just deploy-nobump` | Same without bumping — for verifying a finalised release, or after a failed deploy (ADR-0034) |
| `just release` | Finalise the version for the store (`1.3.12` → `1.4`) and stop, with `test-all` as the gate. Builds nothing, touches no watch |
| `just package` | Signed `publish/Candle.iq`, every product in one bundle. **Refuses a three-segment dev version** |
| `just store-shots [device]` | Crop that device's captures into the listing's square images — the store keeps one set per listing |
| `just link-docs` | Re-point `sdk-docs`/`sdk-samples` after an SDK change |
| `just clean` | Remove `bin/` and `shots/` |

### The version scheme, and why a deploy is free

**The shape of the string says what the build is** (ADR-0039). `tools/version.ps1`
is the only file that knows the rules; `deploy`, `release` and `package` all
dot-source it.

| shape | meaning |
|---|---|
| `1.4` | a **public** version — one digit each side, the minor rolls `1.9` → `2.0`. The only shape the store sees |
| `1.4.12` | a **dev** build, the 12th sideload since `1.4`. Never published |

`just deploy` bumps only the iteration, so **a deploy costs nothing** — which
matters because a deploy against an unplugged watch used to burn a public
number, and did so twice. `just release` finalises; a version that is *already*
public is left alone, which is what lets a first release ship as `1.0` rather
than `1.1`.

The rule nobody has to remember is the one `package` enforces: there is exactly
one route to `publish/Candle.iq` and it refuses three segments. Ceilings are
`9.9` for the public part and three digits of iteration — the scheme's own
ceilings, and `layoutRealLinesFitTheGlass` measures every string they allow on
every device, so both fail with a sentence rather than clipped pixels.

**`just release` deliberately stops before packaging.** The wrist pass sits in
that gap and cannot be automated (ADR-0034), so it prints the next command
instead of running it.

**`just` arguments are POSITIONAL, not `name=value`.** `just test test_name=foo`
silently passes the whole string as the *device* and fails with "not in
manifest.xml". Correct forms:

```
just build fr955 1                           # device, typecheck
just test  vivoactive5 3 candleMathFormatsEvery
pwsh -File tools/test.ps1 -Device fr955 -TestName candleMathFormatsEvery    # clearer
```

### A live simulator blocks the calling shell

The simulator and `monkeydo` both outlive their work and neither exits on its
own. **While either is alive, the shell that started it does not return** — so a
recipe looks hung long after its real work finished, with its output file
already on disk.

Launch flags do not fix this, and one plausible-looking fix makes it worse:
adding `-RedirectStandardOutput` forces `UseShellExecute` off, so the child
*inherits* the shell's handles. The rule that works is **whoever starts the
simulator stops it**. `tools/env.ps1` provides `Start-SimulatorIfNeeded`,
`Stop-Simulator` and `Stop-MonkeyDo`; `shot`/`test` tear down, `just sim` is the
interactive exception. `just shot-keep` keeps the window — and will not return
until you close it.

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

The vívoactive 5 is a **Windows Portable Device (MTP)**: `Get-PnpDevice -Class
WPD` → `USB\VID_091E&PID_514A`, and it **never gets a drive letter**.
`Copy-Item` to `E:\GARMIN\APPS` cannot work; `tools/deploy.ps1` uses the
`Shell.Application` COM namespace instead. It looks for a portable device named
after any supported watch; only the vívoactive 5 has actually been deployed to
from this machine.

> **Never claim a deploy landed.** The only proof is the version on the watch's
> settings screen — ADR-0034, ADR-0032.

`deploy.ps1` bumps the version **before** checking the watch is connected, so a
failed deploy still burns a number. Use `just deploy-nobump` after one.

---

## Reviewing shots/*.png

`just shot` writes the whole simulator window, bezel included. When reviewing:

1. **Clipping at the left/right edges** — the text is wider than the chord at
   that height. If you see it, `Layout` said it would fit and the test is wrong,
   or the code bypassed `Layout`.
2. **Overlapping lines** — anchors closer together than the font height.
3. **Vertical crowding at the poles.**
4. Read the memory figure in the status bar against the 768 KB budget.

`just shot` only captures the **main** screen — the settings screen is a button
press away; `just shot-settings <device>` presses it for you. Review both
screens on **every** device after a `Layout` change: the sweeps prove fit, and
only a picture shows ink (ADR-0015) and proportion.

A screenshot is confirmation, **not** the debugging loop. If a layout question
can be answered by a pure function in `Layout`, write the test instead. The one
thing shots are still the only instrument for is *ink* — a font's advance width
is not its ink, which is how a half-width glyph survived every test (ADR-0015).

---

## Testing

One file per thing under test: `LayoutTest` (geometry, round-screen fit, tap hit
mapping, which rows reach which screen — all measured on the device the runner
is on, ADR-0045), `CandleMathTest` (clamping, conversion, ladders, formatting),
`ClockTextTest`, `MainInputGateTest`, `SettingsTest`, and `input-behaviour.ps1`.

**Nothing that reaches `WatchUi.pushView` or `popView` can be unit tested here.**
Both need a real view stack and the runner has none, so the paths that open and
close the settings screen are asserted only in `input-behaviour.ps1` against a
live simulator.

- Mark tests `(:test)`; they take a `Test.Logger` and return `Boolean`.
- Non-global test methods must be **static**.
- Asserts: `assert`, `assertMessage`, `assertEqual`, `assertEqualMessage`,
  `assertNotEqual`, `assertNotEqualMessage`. (The SDK's own prose table for these
  is garbled — the method list is correct.)
- Put logic in pure modules so it is testable without a running app (ADR-0030).
- **Four tests write to Storage and nothing else may** —
  `settingsStepsWalkEveryRangeEndToEnd`, `settingsVibeProfileTracksSettingChanges`,
  `settingsMigratesLegacyPace`, `settingsPaceStepsWalkTheirOwnLadder`. Each
  because its subject is observable nowhere else, and each restores from a
  `finally` rather than from the end of the happy path — an assertion throws, and
  a restore that only runs on success strands the value the test died on for
  every run after it. That is not hypothetical (ADR-0030).

**Do not weaken a test to make the loop green.** A failing test that reflects
reality is the tool working.

---

## What cannot be tested from here — needs your wrist

- **`Attention.vibrate` does nothing observable in the simulator.** Verification
  stops at the call (ADR-0027). What the motor does with the profile is only
  verifiable on a wrist.
- **A watch with vibration switched off feels identical to a broken app.** If
  nothing is felt and `VIBE OFF` is absent, the fault is below the app and no
  amount of reading this code will find it (ADR-0005).
- **Where the cue stops being felt.** Both floors are deliberately below what a
  body registers, so the bottom of each scale is findable rather than hidden
  (ADR-0023, ADR-0024). Only a wrist can say where it is.
- **How hard the motor actually hits, in m/s².** Not knowable from here and not
  knowable from the watch either — see below.
- Whether a given resonance frequency actually feels right.
- Real memory pressure and battery cost.
- Whether a deploy landed (ADR-0034).

Confirmed on-wrist, so stop re-litigating it: the cue timer keeps running
correctly through a full session with the screen off and the arm down.

---

## Vibration exposure: the watch cannot measure its own motor

Asked once; the answer is a hardware fact, not an opinion. **Candle cannot
report hand-arm vibration in m/s², and no amount of code will change that. Do
not add an accelerometer to try.**

The onboard accelerometer samples far below the actuator's own frequency, so it
cannot see the motion it would need to integrate — it would alias, not measure.
A number derived from it would be confidently wrong, which is worse than absent.

What *is* exactly knowable is duty: cue length × cues per minute, straight from
the settings. That is a rate rather than a dose, so it would pass ADR-0005's
test — and it was still declined, because a number nobody can act on is not a
fact about the session.
