# AGENTS.md — Candle (Garmin Connect IQ, vívoactive 5)

Candle is a Monkey C **watch-app** that vibrates twice per breathing cycle to pace
resonance-frequency breathing. Single target device.

---

## THREE DESIGN DECISIONS THAT LOOK LIKE BUGS. DO NOT "FIX" THEM.

**1. The cue is haptic. There is never a visual breathing indicator.** No
animated arc, no pulsing ring, no phase readout. The app exists to pace breathing
*without* looking at the watch, so a visual cue would invite exactly the
attention it is meant to free. A screen that does not change between pulses is
the intended design, not a gap.

There is exactly one other thing on the main screen that reacts to state, and it
is not a cue either: the bottom slot reads `VIBE OFF` when the watch cannot
vibrate. That reports whether the app can do its job at all — it does not change
between pulses, carries no phase and says nothing about breathing. It is the only
warning that belongs there. A future agent will read rule 1 and want to delete
it; do not.

**Nothing that changes with the breath may ever enter that slot**, and the test
for anything proposed for it is exactly that: does it change between two cues at
fixed settings? A cumulative session dose would — an exposure *rate* computed
from the settings would not. The slot is a function of the settings and the
watch's state, never of where you are in a breath, and it is repainted on the
minute or when a setting changes -- never once per cue.

**What that slot holds when nothing is wrong is the battery charge**, and the
warning takes it outright rather than sharing the line: `"BATT 100%  VIBE OFF"`
measures 265 px against a 220 px chord this near the bottom of a round screen,
and a warning clipped at both ends is the one failure this slot exists to
prevent. `layoutRealLinesFitOnVivoactive5` pins that inequality, so if the
strings ever shrink enough to share, the test says so instead of the glass.

The battery is there on the clock's argument, not on its own: knowing the watch
will last the session, without breaking off the session to find out, IS the job
— the same reasoning that kept the clock when deleting it was proposed. It costs
no repaint, because it rides the clock's minute-gated redraw.

**Three things have been evicted from this slot, and the list is the useful
part** — it is what "earns its place" has meant in practice:

- **The build version**, which moved to the settings screen. The two bottom
  slots now say different kinds of thing: the main screen's is about the session
  you are in, the settings screen's is about the install. You read a version
  once after a deploy and never again while breathing.
- **The Candle mark**, a 40 px bitmap release builds used to draw there. It was
  branding, and it passed rule 1 on a technicality — static, drawn identically
  every frame — but the screen you breathe on is not a place to advertise. The
  mark still identifies the app where identifying it is the job: the launcher
  icon and the store listing. `resources/drawables/logo_small.png`, the
  `LogoSmall` drawable, `candleView.loadLogo` and `layoutLogoFitsTheBottomSlot`
  all went with it, and `tools/make-icons.ps1` stopped emitting the 40 px size.
- **A vibration-exposure readout**, weighed and declined — see the
  vibration-exposure section below for what could and could not have gone there.

**The bar for anything proposed for this slot is that it is a fact about the
session**, and the first thing it has to clear is rule 1: does it change between
two cues at fixed settings? The clock and the battery do not — they change on
the wall clock's schedule and are repainted on the minute. A cumulative exposure
dose would, which is why it was refused; a rate computed from the settings would
not.

The clock at the top is not an exception to that rule either — it tracks the wall
clock, not the breath. It and the battery are the only two things on screen that
change on their own, and the clock is the only reason `timerCallback` requests a
redraw at all: it requests one *only* when the displayed minute changes, so a
session repaints about once a minute rather than eleven times. The battery costs
nothing extra — it is redrawn by that same repaint, so its reading is at most a
minute stale and it asks for no repaint of its own. Every other change requests
its own update.

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

**3. Candle builds nothing the watch or another app already does.** It is a
metronome for the wrist and nothing else. Where a capability already exists
outside the app, Candle delegates to it rather than growing its own copy.

Two things follow from that, both of which read as missing features:

- **Palm safety is the watch's Lock Screen**, not an app-level touch lock. See
  the section below for what reimplementing it cost.
- **There is no session timer.** No duration setting, no elapsed-time display, no
  auto-stop, no start button. Someone who wants a time-bound session runs a timer
  app alongside Candle, which the watch does perfectly well already.

The test for any proposed feature is: does the watch, or an app the user can run
in parallel, already do this? If yes, it does not belong here. Adding it would
buy a little convenience for a permanent increase in the surface that can break —
and the touch lock is the standing proof of how that trade goes. It was a real
feature, correctly motivated, and it could leave the whole watch needing a
reboot.

**Two things on the main screen fail that test on its face and stay anyway: the
clock and the battery.** The watch tells you the time and the charge perfectly
well — the charge is in the controls menu, a button *hold* away. Both are here
because the delegation rule is about *capabilities*, not about *readings*, and
what the watch cannot do is show you either one without taking you off this
screen. Leaving a breathing session to check whether the watch will last it is
the cost being avoided, and it is the same argument that kept the clock when
deleting it was proposed.

Neither is a licence to grow the screen. They are two glances that a session
actually needs, they cost one repaint a minute between them, and the next thing
proposed on the same reasoning should be held to whether it is a glance a session
needs — not to whether it is nice to have on a wrist. A session timer still
fails, and it fails on the harder half of the rule: a parallel app does it
completely, without Candle growing a start button, a duration and an auto-stop.

---

## Repo map — where each concern lives

Orientation only — deliberately no numbers, labels, coordinates, defaults or
pinned strings, because those go out of sync fast and their authoritative
record already exists: the constants in code and the tests that pin them.
**When prose and a test disagree, the test is right** — which is why this map
cites none of them. It also does not repeat what the rest of this file covers
(the three rules above, the toolchain, deploy, testing sections below); it
says where to look.

Two screens — a main screen and a settings screen the upper button pushes over
it — drawn by one view class and served by one delegate class, each told which
screen it is. The difference between the screens is a list of rows and whether
the clock and the bottom line come with them; two classes would have shared
everything else and differed in four lines. Each concern still has exactly one
home:

- **What is on each screen, and in what order** — the `Rows` module. Setting
  identities plus one list per screen. The view draws that list and the
  delegate maps taps through it, so the order cannot be wrong in one place
  and right in the other. Read the section below before touching it.
- **Geometry** — the `Layout` module. Pure functions, never touches a `Dc`, so
  all of it runs under the unit test runner. The round-screen chord maths
  lives here; "fits the bounding box" is not "fits the glass", and that
  distinction is the module's reason to exist. The row grid takes a row count
  rather than pinning one, because the two screens do not carry the same
  number of rows; it never learns which setting is standing in a row.
- **Drawn strings** — the `Display` module. Every string the view draws comes
  from here so the layout tests measure the strings actually drawn
  (measure-what-you-draw). Captions are display words only, deliberately
  decoupled from storage keys, and are looked up by row identity rather than
  by position.
- **State, persistence, the cue timer** — the app class (`candleApp`).
  Settings are integer hundredths in `Application.Storage`, written on
  change. The timer period IS the cue interval; each tick fires exactly one
  cue, and all cues are identical (rule 2). A setting's range, its step and
  one tap's worth of change to it all live here together.
- **Cue arithmetic, ladders, formatting** — the `CandleMath` module, pure for
  the same reason `Layout` is. It also owns which formatter a row's value goes
  through, because the view needs that for the value a watch is holding and
  the layout sweep needs it for every value a watch could hold.
- **Input** — the delegate decodes a tap into a row *position* and a direction
  and looks the setting up in its screen's row list; the input gate
  (`MainInputGate`) is the only discriminator between a physical key and a
  gesture — for `KEY_ENTER` only, which is what still tells the upper button
  from a tap. It no longer guards the exit: the firmware forges `KEY_ESC`, so
  Back is swallowed and a HELD lower button is the only way out. The measured
  event chain is in its own section below — do not re-derive it.
- **Exit diagnostics** — `ExitForensics`, a debug-only breadcrumb, removable
  once the phantom swipe-exit is understood.
- **Build/verify** — everything goes through `just` → `tools/*.ps1`. Test
  builds are debug builds, so release-only rendering is verifiable only via
  the release screenshot recipe. Debug/release forks hang on build-mode
  annotations applied to tiny leaf functions, never to rendering functions,
  so the tests can still measure both outputs.

### Couplings that break silently

- **Storage keys are on-disk API**: renaming one silently resets that setting
  on every installed watch. Changing a setting's UNIT is not a rename — it is
  a NEW key plus a one-time migration; never reuse a key for a new meaning.
- **The manifest id is the store identity**: never regenerate it. The
  manifest `entry` attribute must track the app class name in lockstep.
- **A setting reachable from no screen is still a live setting.** `Rows` is the
  only place that says which screen a row is on; drop one from both lists and
  it keeps its stored value, keeps driving the cue, and has nothing on any
  screen to change it by. `rowsReachEverySettingExactlyOnce` is the guard.
- **The jungle `sourcePath` stays the literal `source;tests`** — the
  self-referencing form drags the SDK junctions into the build.
- **The deploy script greps the app source file for the version constant and
  matches the staged `.prg` by name** — a rename must update it in the same
  commit.

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

Measured font heights on this device: `FONT_XTINY` 32 px, `FONT_TINY` 41 px,
`FONT_SMALL` 48 px, `FONT_MEDIUM` 54 px, `FONT_LARGE` 63 px. These are large
relative to the screen — a common source of overlap bugs. The rows are set in
`FONT_XTINY` and it is not a free choice: at `FONT_TINY` the widest row line goes
from 171 px to 213 px, which alone would take the control radius from 38 down to
about 20.

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
| swipe right | `onDrag(0)`, `onDrag(1)`×n, `onDrag(2)`, **then** `onBack` — **no `onSwipe` at all** |
| swipe left | `onDrag(0)` … `onDrag(2)`, `onSwipe(3)` — and **no behaviour event at all** |
| swipe up | `onDrag(0)`, `onDrag(1)`×n, `onDrag(2)`, then `onNextPage`, `onSwipe(0)` |
| swipe down | `onDrag(...)`, then `onPreviousPage`, `onSwipe(2)` |
| touch hold | `onHold` after the threshold, `onRelease` at lift — no `onSelect`, no `onTap`, **no `onDrag`** |

`KEY_ENTER=4`, `KEY_ESC=5`, `KEY_MENU=7`. The lower button is **one** physical
button: pressed it is Back, held it is Menu.

Three traps, each of which produced a wrong implementation before being measured:

1. **`onSelect` fires BEFORE `onTap`.** Consuming `onTap` cannot suppress a tap.
2. **A right-swipe never raises `onSwipe`.** Filtering `SWIPE_RIGHT` there is
   dead code — it arrives only as `onBack`, indistinguishable at that level from
   the lower physical button. A LEFT swipe raises `onSwipe(3)` and nothing else,
   which is the asymmetry that makes the trap a trap: `onSwipe` exists, it fires,
   and it fires for the one direction that needed no discriminating. **That row
   read "swipe left | nothing" until 2026-08-25**, because nothing implemented
   `onSwipe` — a table entry can only record the events something was listening
   for, and this one was measuring the delegate rather than the device.
3. A tap and the upper button both raise `onSelect`; a right-swipe and the lower
   button both raise `onBack`. **A behaviour event alone cannot tell touch from
   button.**

`DRAG_TYPE_START` = 0, `CONTINUE` = 1, `STOP` = 2 (API 3.3.0).

---

## THE PHANTOM SWIPE-EXIT, SOLVED. Do not re-derive any of this.

**The firmware synthesizes a real `onKeyPressed(KEY_ESC)` for a right swipe.**
Measured on a wrist on 2026-08-25, six reproductions, every one of them a swipe
the wearer made with no button press:

```
P4.R4.T.P5.R5.P5>B!      P4.P5.R5.D0.P5>B!      P5>B!
P4.R4.P5.R5.P5>B!        P5>B!                  R5.D0.D0.D2.S1.P5>B!
```

Every chain ends `P5>B!`. The `B!` tag was only reachable when
`MainInputGate.consume(KEY_ESC)` returned true, and the only thing that ever
latched that gate is `onKeyPressed(KEY_ESC)`. The gate was never buggy. It was
being lied to.

**Three things follow, and the third is the one that decided the fix:**

1. `MainInputGate`'s premise — *"touch gestures never call press()"* — is false
   for `KEY_ESC` on hardware, however true it is in the simulator. It still
   holds for `KEY_ENTER`, which is why `onSelect` can still tell the upper
   button from a tap.
2. The wrist **does** raise `onSwipe(SWIPE_RIGHT)` — see `S1` in the sixth
   chain. The simulator never does. That is the second time the simulator has
   misled us about this exact gesture.
3. **Touch evidence preceded the synthesized key in only two of the six.** Four
   exits arrived with no drag and no swipe recorded at all; two of them had
   literally one event in the ring. So there is no companion event to gate on
   either — a "was there a recent drag?" check would have failed open two times
   in three. **`onBack` cannot be saved. It has to stop deciding.**

`P5.R5.P5` in three of the chains is a swipe on the settings screen (synthesized
key, pop) followed by a swipe on the main screen (synthesized key, exit). The
settings pop recorded nothing at the time, which is why those chains read as one
event too few.

**The fix:** Back is swallowed on the main screen and the exit moved to a held
lower button (`onMenu`), which is the one gesture across this entire
investigation the firmware has never been caught forging — confirmed on the
wrist by holding the button and reading `M` back out of the breadcrumb. A
swallowed Back arms the `HOLD TO EXIT` hint, because an input that changes
nothing on screen reads as a frozen app.

This closes **6 of the 6** observed exits. It does not close a platform-level
exit that never reaches the delegate at all (`…>S`), which nothing in the app
can prevent and which has never been observed here — only the watch's own Lock
Screen guards that.

Trap 3 is now load-bearing twice over, not once. Every tap on the glass raises
`onSelect`, and the upper button — which raises the same `onSelect` — is what
opens the settings screen. Without the gate, adjusting a value would open a
screen; with it, the press is told apart by the `onKeyPressed(4)` that arrives
immediately before it and never arrives for touch.

## What each button does, on each screen

| | main screen | settings screen |
|---|---|---|
| upper button (press) | push the settings screen | pop back |
| upper button (held) | the watch's controls menu — never reaches the app | same |
| lower button (press → Back) | swallowed, shows `HOLD TO EXIT` | pop back |
| right-swipe (arrives as Back) | swallowed, shows `HOLD TO EXIT` | pop back |
| **lower button (held → Menu)** | **exit the app** | **exit the app** |

**Back never exits. A held lower button is the only way out, from either
screen.** That is not a preference, it is forced — see the phantom-swipe section
below. The firmware synthesizes a real `KEY_ESC` for a right swipe, so `onBack`
cannot tell a thumb from a sleeve on this hardware, and the exit had to move to
a gesture the firmware does not forge.

`System.exit()` ends the app "cleanly from any point within an app", so one
handler serves both screens. Restricting the exit to the main screen would have
cost a branch, not saved one — and "hold the lower button to quit, from
anywhere" is one rule rather than two.

A right-swipe is still honoured on the settings screen, where it pops. It costs
a wearer nothing there — the cue timer lives in the app and never stopped — and
swallowing it would break the one gesture every other app on the watch honours.

## Palm safety belongs to the watch, not to Candle

**Never call `WatchUi.configureTouchEvents`.** Candle used to, and it is the only
thing this project ever did that could damage the watch.

The problem is real: covering much of the screen with skin triggers a
platform-level exit that never reaches the delegate, which would end a session
silently. `configureTouchEvents({ :enabled => false })` suppresses it. But that
setting is **watch-global and outlives the app**, restoring it is fallible — the
simulator rejects `:enabled => true` every single time — and a leak leaves the
whole watch untouchable until it is rebooted. That happened repeatedly on the
wrist, and Candle could not even repair it, because relaunching Candle to run the
restore requires touch to reach the app list.

The vívoactive 5 already ships the feature: **hold the upper button → controls →
Lock Screen.** Confirmed on the wrist, and better than the app's version in every
respect:

- It works inside a running app, Candle included.
- It locks the **buttons as well as the touchscreen**, so a stray lower-button
  press cannot end a session either — protection the app-level lock never had.
- The OS owns the state and restores it, so there is nothing to leak and no
  reboot to recover from. Worst case is now a lost session, not a bricked watch.

So Candle holds no touch state at all. What that deleted: `TouchControl.mc`,
`_touchLocked`, `isTouchLocked`, `setTouchLocked`, `applyTouchLock`, the dimmed
rendering of the controls, the lock branches in `onSelect` and `onTap`, and three
lifecycle callbacks that existed only to restore touch — `candleView.onShow`,
`candleView.onHide` and `candleApp.onInactive`.

**Back does not exit at all any more, on either screen.** The rule it carries is
now *which screen it arrived on*: it pops the settings screen and it is swallowed
on the main screen, where it arms the `HOLD TO EXIT` hint and nothing else.
Neither branch consults any state Candle owns, and neither branch asks a question
the hardware refuses to answer honestly. The exit is a **held** lower button.

Three versions of the exit have now been deleted, and the reasons are different
enough to be worth keeping apart. The first two — a four-second two-press
confirmation with an `armed`/`requested`/`restored` triple and two timers, then a
single check of the lock flag — existed only because Candle disabled a
watch-global touch setting and had to restore it. Both went when the Lock Screen
took that job. The third, a plain `consume(KEY_ESC)` gate, went for a completely
different reason: **it was asking a question the firmware answers falsely.**

The upper button had lost its only job when the app-level lock went. It has one
again: it pushes the settings screen and pops it. Holding it still opens the
watch's controls menu, which never reaches the app and is where Lock Screen
lives — a hold and a press, so the two cannot collide.

**The discriminator that survives:** `onKeyPressed` fires for physical buttons
and never for touch — **for `KEY_ENTER`.** `candleDelegate` latches the last key
press and consumes it inside `onSelect`, which is what tells the upper button
apart from a tap, and that still works. It is **not** true for `KEY_ESC`, and
`MainInputGate`'s header says so. Do not give the gate `KEY_ESC` work back
without new evidence from a wrist, and do not replace any of this with `onTap`
filtering.

Gesture thresholds live in the device config: swipeRight only counts as Back
when it starts within `maxDistToEdge` (81px) of the edge, travels more than
`minSwipeDeltaX` (78px), and finishes inside `maxSwipeDuration` (250ms).

`just input-test` confirms that taps reach the right control on both screens,
that swipes are swallowed on the main screen, that the upper button really opens
and closes the settings screen, and that the lower button closes the app — it
asserts the process is gone afterwards, not just that a trace line appeared, and
it asserts the process is *still there* after Back on the settings screen, which
is the assertion a trace line alone would pass on an app that had just died. It
is separate from `just test` because it needs a simulator window and synthesises
system-wide mouse events (it steals the pointer for ~60s).

Every close of the settings screen is followed by re-opening it, so each of the
three ways out is driven from a screen that really is on the stack rather than
from wherever the previous check left things.

Order matters in that script for one reason now: **a HELD lower button is the
only thing that closes the app, so its check must be last** and nothing may
follow it but the process check. A pressed lower button and a right swipe are
both asserted to leave the app *running* — that pair is the phantom-swipe fix,
and a regression there is the one this script exists to catch. The script used to
need a second throwaway instance for the ordering, because the app-level lock had
to survive the earlier checks; with the lock gone, one launch does the whole run.

## Round screen: the bounding box is not the screen

The display is a **circle**. Text that fits within 390 px of width still gets
clipped near the top and bottom, where the usable chord is far narrower. At the
bottom of the version line's glyph box (y≈353) the usable width is ~228 px, not
390; another 13 px lower it is ~190 px. This is why the clock is centred in the
band above the first row instead of pinned near the top edge — at y=12 it would
have had ~134 px for the largest font on the screen, against ~168 px where it
now sits.

The same fact is why the row grid is **centred on the glass** rather than hung
from a fixed top edge. The control circles are what run out of room first, and
every pixel a row sits away from the vertical centre is a pixel its circles have
to give back — which is exactly what dropping the third row bought: two rows can
sit closer to the middle than three could, and that is where the larger controls
came from.

`source/Layout.mc` models this with `halfChordAt()` and `fitsOnRoundScreen()`.
**All layout coordinates must come from `Layout`.** Do not put literal pixel
offsets in `candleView.mc` — that is exactly the bug the tests exist to catch.

**The same rule applies to strings, via `source/Display.mc`.** A fit test can
only be trusted if it measures the string the view actually draws. The layout
test spent several commits asserting that `"v0.22  UNLOCKED"` fit, on a screen
that had been drawing `"v0.22  EDIT"` the whole time — green, and measuring
nothing. Both of those strings are gone now — the lock state was being spelled
out in words on two lines while the row controls were already showing it by
dimming — but the rule they cost is permanent. `Display` holds the captions and
`CandleMath.format*`/`ClockText.formatTime` hold the value strings; `candleView`
and `LayoutTest` both read from there, so the two cannot diverge.

**Captions are display strings and nothing else, and two of the three do not
match the code under them.** The rows read `PULSE` over
`_vibeDuration`/`vibrationDuration` and `POWER` over
`_vibeStrength`/`vibrationStrength`. A caption can be re-worded in `Display.mc`
alone; a **storage key cannot be re-worded at all**, because it is on the watch's
disk and renaming it silently resets that setting on every watch running the app.
When a setting's *unit* changes, that is not a re-wording either — it is a NEW
key plus a one-time migration, which is exactly what `everyHundredths` is: the
old `paceHundredths` held hundredths of a breath per minute, the new key holds
hundredths of a second between cues, and `migrateLegacyPace` converts the old
value once and deletes the old key.

The `EVERY` value is the bare cue interval in seconds — `5s`, `5.25s` — with no
translation on screen: whoever thinks in breaths per minute converts once,
outside the watch. The unit sits tight against the number on every row (`5s`,
`100ms`, `20%`), trailing zeros drop, and the line changes width as it is tapped
through.

## Row order lives in exactly one place, and that is the point

`Rows.forScreen` returns a screen's rows in the order it draws them. `candleView`
iterates that list to draw and `candleDelegate` indexes the same list to decide
what a tap edited, so the two cannot disagree about anything: they are reading
the same array.

**It was not always so, and the arrangement it replaced is worth knowing about
because the failure mode is silent.** The order used to be written down twice —
in the `ACTION_` constants in `Layout.mc`, which encoded a row's position *and*
the setting standing on it in one number (`ACTION_EVERY_UP` and friends), and in
the `drawEditorRow` calls in `candleView.mc`. The delegate dispatched on those
constants by name, so it needed no edit when the order changed, which is exactly
what made it dangerous: if the two lists disagreed, everything still compiled,
every test that did not check the mapping still passed, and every tap silently
edited a different setting than the one under the thumb.

A second screen made that encoding untenable anyway. Position 0 is `PULSE` on the
main screen and `EVERY` on the settings screen, so a constant cannot name both.
`Layout.editorHitAt` now returns a position and a direction and nothing else, and
`Layout.hitRow`/`hitIsIncrease` take it apart. Neither `Layout` nor
`candleDelegate` names a single setting.

Three tests hold the line: `editorLayoutMapsEveryControlOnEveryScreen` walks
every control of every screen, `rowsReachEverySettingExactlyOnce` catches a
setting dropped from both lists or listed on both, and
`tests/input-behaviour.ps1` proves it against real taps on a real simulator.

**Which rows sit where is a design decision, not an arbitrary one.** The main
screen carries `POWER` over `PULSE` — the two settings a session reaches for — and
the settings screen carries `EVERY`, which is measured once and then left alone.
Moving it off is what paid for controls half again as large on the two that
remain. It is parked, not hidden: one button press away, and still the setting the
whole app is built around.

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
a 10 px gutter each side — and `layoutEveryReachableValueFits` checks **both**
budgets for every reachable value, labels included, on both screens. Any new
caption or value format has to clear it.

**The widest line the app can produce is `"PULSE 250ms"` at 171 px, not the
`EVERY` row.** That is worth spelling out because the guardrail got it wrong for
several commits: `layoutHitZonesClearRealisticText` measured the `EVERY` row
alone, called `CONTROL_HIT_EDGE = 110` clear, and the hit zone had been reaching
under the `PULSE` line the whole time — `EVERY` at its widest (`"EVERY 14.95s"`)
is 168 px, three short. The test now sweeps every row of every screen and picks
the widest itself; the edge came back to 108.

Coverage is exhaustive rather than sampled. That same sweep walks **every** value
the tap controls can reach — 1837 lines over the two screens, every interval,
every strength, every length, each at the anchor its own screen gives it — and
`layoutEveryClockMinuteFits` every minute of the day in both clock formats,
rather than a hand-picked worst case. A row's anchor depends on how many rows
share its screen, so screen and row index are not interchangeable in any of it.
`layoutDisplayWidthMatchesTheDevice` pins `Layout.DISPLAY_WIDTH` — which
`candleDelegate` maps taps with, as both width and height — to
`System.getDeviceSettings().screenWidth`, which is what `candleView` draws with.

There is a third budget, and it only appeared once the controls got large: two
rows stacked 102 px apart at radius 38 leave **20 px of air between their
circles**, and the chord maths cannot see that collision either — both circles
are comfortably on the glass while overlapping each other.
`layoutRealLinesFitOnVivoactive5` checks it. The circle-in-circle fit in that
same test counts the ring's pen width as if the whole stroke fell outside the
radius, which is the conservative reading of a detail the SDK does not document.

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

### When Smart App Control blocks the SDK manager

`connect-iq-sdk-manager.exe` is unsigned and carries no reputation, so Windows
Smart App Control refuses to launch it: every `just` recipe dies at `env.ps1`
with *"An Application Control policy has blocked this file"*, and the
CodeIntegrity log records event 3077 against it. `monkeyc` itself is unaffected —
only the manager is blocked.

Smart App Control **cannot be switched back on once it is off**, short of
reinstalling Windows, so turning it off to compile is a one-way door. Set
`CIQ_SDK_BIN` to the SDK's `bin` directory instead; `env.ps1` takes it in
preference to the manager and everything downstream only ever wanted that path.

```
$env:CIQ_SDK_BIN = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin"
```

The cost is that the manager is no longer arbitrating which SDK is active, so
`CIQ_SDK_BIN` has to be re-pointed by hand after an SDK upgrade — the same edit
`just link-docs` needs.

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
| `just input-test` | Drive real taps/swipes/button presses into both screens and assert which handler fires (~60s, steals the pointer) |
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
just test  vivoactive5 3 candleMathIntervalIsTenTimesTheValue
pwsh -File tools/test.ps1 -TestName candleMathIntervalIsTenTimesTheValue   # clearer
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
  — **no `.prg` at all**, despite Candle being installed on the watch.
- Straight after `CopyHere`, `candle.prg` **does** appear in the listing.
- The shell reports `Size=0` for it — but it reports `Size=0` for `OUT.BIN` too,
  so sizes are simply not exposed over MTP. A visible name proves an entry
  exists and nothing about whether the bytes arrived intact.
- Once the firmware installs the app the entry disappears again, which is why
  the directory looks empty between deploys.

So the listing is worthless as verification in both directions. The **only**
proof a deploy landed: launch Candle on the watch, **press the upper button**,
and read the version off the settings screen. That is why `just deploy` bumps
`APP_VERSION` in `source/candleApp.mc` before every build. If the watch shows an
older version, it is still running the old build.

It is one press further away than it used to be, and that is deliberate: the
version is a development instrument and the main screen is where you breathe. You
read it once, right after a deploy, and never again during a session. **The
previous run's exit breadcrumb moved with it**, for the same reason and to the
same slot — the phantom-exit hunt now reads `relaunch → upper button → read`.

**The version is drawn in debug builds only**, behind `Display.showsBuildVersion`
— a Store install has the Connect IQ app to report its version, so drawing it
there is the duplication the delegation rule rejects. This is safe precisely
because `deploy.ps1` calls `build.ps1` **without** `-Release`: every sideload is
a debug build, so the one workflow that cannot verify itself is the one that
keeps the version. If a release flag is ever added to the deploy path, this
verification loop dies silently — the watch would simply stop showing a version
and every deploy would look identical.

Unit tests compile with `-t`, which is a debug build, so **tests cannot see
`(:release)` code at all**. That is why `Display.buildLine` takes the flag as an
argument and only a one-line predicate is annotated, and why `just shot-release`
exists. Verified both ways: the release build draws no version, the debug build
draws `v0.24`.

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
   the gap against the measured heights above.
3. **Vertical crowding at the poles.** The top and bottom of a round display have
   very little usable width.
4. Read the memory figure in the simulator status bar against the 768 KB budget.
5. **The glyph inside a control.** Whether a `-` or a `+` reads as centred and
   proportionate inside a 76 px ring is not something any test in this repo can
   see; the font for it was picked by eye on a shot and can only be re-picked
   the same way.

`just shot` only ever captures the main screen — it launches the app and grabs a
frame, and the settings screen is a button press away. To see that one, drive the
press in with `tools/input.ps1 -Action press -Target enter` between the launch
and the capture.

A screenshot is confirmation, **not** the debugging loop. If a layout question can
be answered by a pure function in `Layout.mc`, write the test instead.

---

## Testing

Tests live in `tests/`, wired via `base.sourcePath = source;tests` in
`monkey.jungle`. They are compiled in only with `-t`, so they cost nothing in a
normal build (106.5 KB vs 132.3 KB).

One file per thing under test, and no more: `LayoutTest` (geometry, round-screen
fit, tap hit mapping, and which rows reach which screen), `CandleMathTest`
(clamping, pace arithmetic, formatting), `ClockTextTest` (both clock formats),
`MainInputGateTest` (button-vs-touch, and the unlocked-start invariant),
`SettingsTest`, `input-behaviour.ps1`.

**Nothing that reaches `WatchUi.pushView` or `popView` can be unit tested here.**
Both need a real view stack under them and the test runner has none, so the paths
that open and close the settings screen — the upper button, and Back on the
settings screen — are asserted only in `input-behaviour.ps1`, against a live
simulator. The unit tests drive the main screen's delegate and the touch paths,
which reach neither.

- Mark tests `(:test)`; they take a `Test.Logger` and return `Boolean`.
- Non-global test methods must be **static**.
- Asserts available: `assert`, `assertMessage`, `assertEqual`,
  `assertEqualMessage`, `assertNotEqual`, `assertNotEqualMessage`.
  (The SDK's own prose table for these is garbled — the method list is correct.)
- Put logic in pure modules (`Layout`, `CandleMath`) so it is testable without a
  running app instance.
- **Four tests write to Storage, and nothing else may** —
  `settingsStepsWalkEveryRangeEndToEnd`, because walking the real setters is the
  only way to prove they clamp; `settingsVibeProfileTracksSettingChanges`,
  because the `VibeProfile` the motor is handed can only be reached through those
  same setters; `settingsMigratesLegacyPace`, because a key-to-key migration
  is observable nowhere else; and `exitForensicsChainsAndPersists`, whose
  subject is a Storage-persisted diagnostic. All four restore from a `finally`, not from the
  end of the happy path: an assertion throws, and a restore that only runs on
  success strands whatever value the test died on in the simulator for every run
  after it. That is not hypothetical; it happened. Keep new tests pure.

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

  Two consequences worth knowing there. An **interval** (`EVERY`) change
  restarts the timer, so the next cue is a full new interval away and the phase
  resets — one breath, by design. A **strength or length** change does not: it
  lands on the next cue, which can be up to 15 s later at the ceiling, so a tap
  will not alter a buzz already in flight.

- **A watch with vibration switched off feels identical to a broken app.** This
  is the one failure mode the app can see, so as of v0.23 it says so: the main
  screen's bottom slot reads `VIBE OFF` when `Attention has :vibrate` is false or
  `System.getDeviceSettings().vibrateOn` is off. If nothing is felt on the wrist
  and that warning is absent, the fault is below the app and no amount of reading
  this code will find it.
- **Where the cue stops being felt.** The strength floor is 2% and the length
  floor 10 ms, both deliberately below what a body registers, so the bottom of
  each scale is findable rather than hidden. Only a wrist can say where it is.
- **How hard the motor actually hits, in m/s².** Not knowable from here and not
  knowable from the watch either — see the section below.
- Whether 5.71 breaths/min actually feels right.
- Real memory pressure and battery cost.
- Whether a deploy landed (see above).

Confirmed on-wrist, so stop re-litigating it: the cue timer keeps running
correctly through a full session with the screen off and the arm down.

---

## Vibration exposure: the watch cannot measure its own motor

This has been asked once and the answer is a hardware fact, not an opinion.
**Candle cannot report hand-arm vibration in m/s², and no amount of code will
change that.** Do not add an accelerometer to try.

The number people want is ISO 5349-1's: `a_hv`, the frequency-weighted (W_h) RMS
acceleration, and `A(8) = a_hv × sqrt(T / 8h)`, the eight-hour energy-equivalent
exposure that the EU directive's 2.5 m/s² action value and 5.0 m/s² limit value
are quoted against. Two independent things stop it:

**1. The accelerometer is far too slow.** From the device's own config —
`%APPDATA%\Garmin\ConnectIQ\Devices\vivoactive5\simulator.json` —

```
"sensorSampleRate": { "highFrequencyRate": true, "maxAccelRate": 100, "maxMagRate": 50 }
```

100 Hz is the ceiling, so Nyquist is 50 Hz. A haptic actuator in a watch runs an
order of magnitude above that — an LRA sits at its resonance, typically somewhere
around 150–250 Hz, and anything that feels like a *buzz* rather than a series of
separate thumps is by definition well over 50 Hz. Every bit of the vibration is
above the sampling limit, so it does not get measured badly; it does not get
measured at all. What comes back is alias, further mangled by the sensor's own
anti-alias filter. W_h weighting needs the 8–1000 Hz band, and this API can offer
0–50 Hz of it.

**2. The one constant that would let it be computed is not published.** With no
measurement, the only route is a model: weighted acceleration at full drive,
times the drive, times the square root of the duty. Candle knows the drive and
the duty exactly. It does not know, and cannot find out, what the actuator does
at full drive — Garmin publishes no figure, it varies with how tight the strap
is, and the instrument that would settle it is a HAV meter, not a phone.
**Any m/s² Candle printed would be that unknown constant wearing a measurement's
clothes.** That is worse than printing nothing.

### What IS exactly knowable, and is the useful number anyway

`POWER`, `PULSE` and `EVERY` are all known to the app, so the *shape* of the
exposure is known exactly even though its scale is not:

- **duty** = `PULSE / EVERY` — the fraction of the session the motor is running.
  Multiply by 3600 for motor-seconds per hour.
- **energy-equivalent drive** = `POWER × sqrt(PULSE / EVERY)` — the steady drive
  that would deliver the same vibration energy as the current pulsed pattern.
  That `sqrt(duty)` is exactly the arithmetic ISO 5349 uses for `A(8)`, with the
  unmeasurable constant factored out rather than guessed. It is a percentage of
  the actuator's own full-drive output, and it is the number to watch when
  trading `POWER` against `PULSE`.

Both are ratios of settings, so they change when a setting changes and never
between two cues — which is what lets either sit in the main screen's bottom slot
without breaking rule 1. **A cumulative session dose would break it**, and is the
version of this feature to refuse: it would change with the breath and force a
repaint per cue, which is the exact cost the clock's minute gating exists to
avoid.

One caveat on both: `Attention.vibrate` is fire-and-forget. The app knows what it
*asked* the motor for, never what the motor did — a watch in Do Not Disturb, or
with vibration off, runs the same arithmetic and delivers nothing.

For scale, using a generous placeholder for the unknown constant: the default
settings land around 1% of the EU action value, and the app's absolute ceiling —
`POWER 100%`, `PULSE 250ms`, `EVERY 0.25s`, held for a full hour — still lands
under it. Treat that as an order of magnitude and not a result; the constant it
rests on is the one nobody has measured.
