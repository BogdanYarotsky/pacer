# Candle

**Candle: Haptic Resonance Breathing Frequency Pacer**, for the Garmin
vívoactive 5. Free and open source under the [MIT license](LICENSE).

Candle is a resonance-frequency breathing pacer. It vibrates twice per breathing
cycle — once at each turn-around — and does nothing else. There are two screens
and no menus. The cue is haptic and always will be; there is no visual pacing
element, because the point is to pace your breathing without looking at a watch.

**The two cues are deliberately identical, and that is the whole design.**
Inhale and exhale are the same length, so the two boundaries are
interchangeable, and what you feel is simply a metronome at twice your breath
rate. Which pulse is which does not matter and is not encoded. That is not a
limitation to be fixed — it is what makes the pacer self-healing. Lose your
place, catch a stray notification buzz, get distracted for half a minute, and
you rejoin on the very next pulse with nothing to count and no way to be wrong.
Making the two cues distinguishable would destroy that to solve a problem
symmetric breathing does not have.

The setting is the bare interval between cues, in seconds. It starts at
**5.00 s** — 10 s per breath, 0.1 Hz, the Lehrer resonance protocol's canonical
frequency and the population average the literature converges on — because that
is where to start looking, not an answer.

## Finding your own frequency

Resonance frequency is individual: measure your own and dial it in on the watch
rather than in code. Tools built for exactly that measurement include
**Yudemon** and **Elite HRV** — run an assessment there and type the breathing
rate it settles on straight into the `BPM` row. A measured 5.5 breaths/min is
`5.5 BPM`, and there is no arithmetic to do.

There is no arithmetic because the same screen carries both units. The `BPM` row
is breaths per minute, `EVERY` is seconds between cues, and they are one setting
seen twice — move either and the other follows. Use whichever your tool speaks:
assessments report bpm, so `BPM` is usually the one you type into, and `EVERY`
is the finer nudge afterwards (in the resonance band one `BPM` tap is worth
several `EVERY` taps).

That row carries no caption of its own — the unit is the caption. If "5.88 BPM"
means nothing to you, ignore it and work the `EVERY` row above: the number below
will follow along, which explains the pair better than a label could.

## Using it

The main screen shows the time, the two settings you actually reach for during a
session, and the charge left. Only two things on it change on their own — the
clock and the battery — and both are repainted once a minute:

```
                    07:42


        (−)      POWER 20%       (+)


        (−)      PULSE 100ms     (+)


                 BATTERY 80%
```

The bottom line shows the charge left, `VIBE OFF` if the watch cannot vibrate,
or `HOLD TO EXIT` for two seconds after you press Back.

**Press the upper button for the pace.** It is the setting you measure once and
then leave alone, so it lives on a screen of its own rather than costing the
other two a third of the glass. **Press the same button again to come back** —
that one press is the whole navigation, in both directions.

Back and a right swipe do nothing here, exactly as on the main screen, and both
answer with the same `HOLD TO EXIT`. That is the firmware quirk described below:
a right swipe arrives as a real button press, so a sleeve across the glass used
to close this screen out from under the value you were adjusting.

```
                 Candle v1.0


        (−)      EVERY 5s        (+)

        (−)      6 BPM           (+)


```

The title at the top is drawn in every build, store installs included — it is
the version to quote in a bug report. Nothing is drawn along the bottom until a
swallowed Back puts `HOLD TO EXIT` there for two seconds. Otherwise the screen
is its two rows and the two physical buttons, which is the point: there is no
control here small enough to mis-tap while you are adjusting a value.

| Setting | Where | Default | Range | Step per tap |
| --- | --- | ---: | ---: | ---: |
| Vibration strength — the `POWER` row | main | 20% | 1–100% | 5%, and 1% at 5% and below |
| Vibration length — the `PULSE` row | main | 100 ms | 10–250 ms | 10 ms |
| Seconds between cues — the `EVERY` row | upper button | 5.00 s | 3–15 s | 0.05 s, snapped |
| Breaths per minute — the `BPM` row | upper button | 6.00 bpm | 2–10 bpm | 0.01 bpm |

**The two steps do different jobs.** `BPM` is the precision instrument: 0.01 bpm
is what an assessment tool like Yudemon reports, so whatever number it hands you
goes in verbatim. `EVERY` is the coarse one, and its taps **snap to the ladder**
rather than adding to the current value — so after `BPM` leaves the interval at
5.236 s, one tap down gives you 5.20 s and the next 5.15 s, instead of walking
5.186, 5.136 and never touching a round tenth again.

`EVERY` is the number the timer runs, exposed with no translation: one buzz
every that many seconds. It is half a breath, since there are two cues per
breath — and you can check it against any clock by counting one gap between
buzzes. `BPM` is that same number as a breathing rate, and the two rows are one
setting: 3–15 s and 2–10 bpm are the same range in two units, endpoints included.

Note that `+` moves them in opposite directions, and that is not a bug — more
breaths per minute is *less* time between cues. Reciprocal units cannot agree on
which way is up.

The ranges are generous rather than tight. The documented resonance bands are
4.5–7.0 bpm for adults and 6.5–9.5 for children, so a 10 bpm ceiling clears
every one of them; past that you are into ordinary resting respiration, which
wants no metronome. The 15 s ceiling — 30 s per breath — is far past any
breathing practice at the other end.

Trailing zeros are dropped, so 5.00 reads `5s`. The line therefore changes width
as you tap through it, and being centred it shifts under the thumb rather than
growing to one side.

Tap the `−` and `+` circles to change a value, or hold one to repeat at five
steps a second until you let go. The centre text is deliberately inert, so
reading a value can never change it. Values are written to
`Application.Storage` immediately and survive app restarts.

**There is no mute.** Strength bottoms out at 1%, not 0%, because the useful
question at the bottom of the scale is "can I still feel this?" and silence
cannot answer it. Both floors sit deliberately *below* what a wrist is likely to
register, so the threshold is somewhere you can find rather than somewhere the
range hides:

- `VibeProfile.dutyCycle` is documented as 0–100%, so the scale is the entire API
  range minus silence. Taps walk it in 5% strides, switching to 1% at 5% and
  below — the fine zone exists because the hardware's real threshold hides at
  the bottom. A rotating-mass actuator has a duty cycle below which it does not
  turn at all — often quoted near 30% for PWM drive — so expect a dead band at
  the bottom that is the motor's, not the app's.
- `VibeProfile.length` has **no documented bounds** in the SDK at either end;
  10–250 ms is entirely this app's choice. Published vibrotactile work puts the
  shortest perceivable pulse near 30 ms and rhythmic patterns nearer 50 ms, and
  actuator rise time is the harder limit at 50–100 ms to full amplitude. The
  ceiling is 250 because a pulse long enough to be felt as a buzz rather than a
  tick has stopped being a metronome beat, and use in practice stays under
  ~200 ms.

None of that is verifiable from a computer: `Attention.vibrate` does nothing
observable in the simulator. Sweep it on your own wrist.

**Locking the screen is the watch's job, not Candle's.** Hold the upper button →
controls → **Lock Screen**. It works inside a running app, and it locks the
buttons as well as the touchscreen, so nothing — a sleeve, a palm, a knock
against a doorframe — can reach Candle while you breathe. Unlock the same way.

Do that before a session. Without it, a palm across the screen can trigger a
platform-level exit that Candle never sees and cannot prevent.

Candle had its own touch lock once, built on
`configureTouchEvents({ :enabled => false })`. It worked, but that setting is
*watch-global* and outlives the app: when restoring it failed, the whole watch
was left without touch until it was rebooted — and Candle could not repair it,
because relaunching Candle needs touch to reach the app list. The watch's own lock
has none of that failure mode, because the OS owns the state and restores it.

**Upper button — the interval, and the only way between the screens.** Press it
to open the `EVERY` screen and press it again to close. Held, it opens the
watch's controls menu, which is where Lock Screen lives — a hold, not a press,
so the two do not collide.

**Lower button — Back, and it never does anything.** On either screen it shows
`HOLD TO EXIT` for two seconds and nothing else. Same for a right swipe, which
arrives as the identical event.

**To quit, hold the lower button.** From either screen.

That looks like an odd choice and it is not one — it is forced. On this watch the
firmware **synthesises a real button press for a right swipe**, so nothing in the
app can tell your thumb from a sleeve brushing the glass, and Candle used to end
sessions because of it. Six exit traces off a wrist say so; the full working is
in `AGENTS.md`. A *held* button is the one gesture the firmware does not forge,
so that is where the exit went.

Lock the screen during a session (below) and nothing can reach Candle anyway.

**The bottom line is the battery**, and it is there for the same reason the clock
is: leaving a breathing session to find out whether the watch will last it is the
thing worth avoiding. The watch shows you the charge too, but only in the
controls menu — a button hold and a screen away from the breath.

**When it reads `VIBE OFF` instead, the watch cannot vibrate** — either the
system vibration setting is off or the device has no motor. Candle will run a
flawless session and you will feel nothing, so it says so rather than leaving you
to tell that apart from a dead app. It is the only warning in the app, and it
takes the whole line: the two do not fit side by side down there, and a warning
clipped at both ends would be worse than no warning at all.

**The version is the settings screen's title, in every build.** `Candle v1.0`
sits at the **top** of that screen, one button press away — you read it after a
deploy, or when you are writing a bug report, and never while breathing.

It is one number doing two jobs. A sideload to this watch goes over MTP and
*cannot* be verified from the host (see the deploy section of `AGENTS.md`), so
reading the version off the glass is the only proof of which build is running —
which is why `just deploy` bumps it before every build. And it is the number to
quote in a bug report, matching the store listing exactly, because the minor is
that same sideload counter and whatever it says on submission day is what gets
typed into the store form. Store versions therefore skip: 1.0, then 1.7. That is
the deal, and the alternative is a tidy number that traces to nothing.

The minor is a plain integer, so it counts 1.9 → 1.10 and never grows a trailing
zero. Release builds once drew a small candle mark at the bottom of the main
screen; it is gone, because the screen you breathe on is not a place to
advertise, and the battery has that slot now. The mark still identifies the app on
the launcher and in the store listing, which is where identifying it is the job.

## Build and run

Everything goes through `just`; see `AGENTS.md` for the full recipe list and for
the toolchain versions this is pinned to.

```
just build      # compile for vivoactive5 at strict typecheck (-w -l 3)
just test       # build with -t, run the unit tests in the simulator, fail loudly
just sim        # launch the simulator and load the app
just shot       # capture the simulator window to shots/vivoactive5.png
just shot-release # same, of the release build -- the only way to see (:release) code
just deploy     # bump the iteration, build, push to the watch over MTP
just input-test # drive real taps and button presses into the simulator (~40s)
just release    # finalise the version for the store (1.3.12 -> 1.4) and stop
just package    # signed publish/Candle.iq -- refuses a dev version
```

`just build` and `just test` are the loop. Nothing is finished until both pass.

**Two version shapes, and the shape is the meaning.** `1.4` is public — one
digit each side of the dot, the minor rolling `1.9` → `2.0` — and it is the only
form the store ever sees. `1.4.12` is the 12th sideload since `1.4`, never
published. `just deploy` bumps only the iteration, so deploying is free;
`just package` refuses three segments, which is the one place the rule is
enforced rather than remembered.

### First-time setup

1. A 64-bit JDK 21 (Temurin) with `JAVA_HOME` set.
2. `connect-iq-sdk-manager`, with SDK 9.2.0 selected and the vívoactive 5 device
   package downloaded **with `--include-fonts`** — without the fonts the
   simulator dies the moment it draws text.
3. A 4096-bit RSA developer key at `%USERPROFILE%\.garmin-keys\developer_key.der`,
   pointed to by `$env:GARMIN_DEVELOPER_KEY`. The key is machine-level and shared
   by every Connect IQ app; it never lives in this repo. Generate one with
   `Monkey C: Generate a Developer Key` in VS Code and back it up — losing it
   makes Store updates for anything signed with it impossible.
4. `just link-docs` to point `sdk-docs`/`sdk-samples` at the active SDK.

On a fresh machine, `~/bin/garmin-bootstrap.ps1` does 1–3 idempotently and prints
the two steps that cannot be scripted (accepting the SDK licence, the Garmin SSO
login).

If Windows Smart App Control blocks `connect-iq-sdk-manager.exe` — every recipe
dies with *"An Application Control policy has blocked this file"* — set
`CIQ_SDK_BIN` to the SDK's `bin` directory and the build stops needing the
manager at all. Turning Smart App Control off is a one-way door on Windows and
not worth it to compile; `AGENTS.md` has the detail.

Garmin's own setup guides:

- <https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/>
- <https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/>
- <https://developer.garmin.com/connect-iq/core-topics/security/> (developer keys)

### Installing on the watch

`just deploy` bumps `APP_VERSION`, builds, and copies the PRG to `GARMIN\APPS`
over MTP. Then launch Candle on the watch and check the version on screen against
what the script printed. If it shows an older version, the watch is still running
the old build.

A differently signed build with the same app id must be uninstalled from the
watch first — and that wipes the stored pace, strength and length.

## How the source is organised

Anything that can be a pure function is one, so it can be unit tested without a
running app, a graphics context or a simulator window.

| File | Responsibility |
| --- | --- |
| `source/candleApp.mc` | Settings, storage, the cue timer, app lifecycle |
| `source/candleView.mc` | Both screens — draws, decides nothing |
| `source/candleDelegate.mc` | Input — telling a button press from a touch |
| `source/Rows.mc` | Which settings are on which screen, in what order |
| `source/MainInputGate.mc` | Tells a physical button from a touch gesture |
| `source/Layout.mc` | Every coordinate, including round-screen chord maths |
| `source/Display.mc` | Every string the screen draws |
| `source/CandleMath.mc` | Cue arithmetic, the POWER ladder, clamping, formatting |
| `source/ClockText.mc` | Clock rendering, 12- and 24-hour |

`Layout` and `Display` exist so the tests measure the real coordinates and the
real strings. A literal pixel offset or caption in `candleView.mc` puts it beyond
the reach of the test that is supposed to cover it — both classes of drift have
shipped here before.

`Rows` exists for the same kind of reason. A screen's row order used to be
written down twice, once in the tap map and once in the draw calls, and if the
two disagreed everything still compiled and every tap silently edited a different
setting than the one under your thumb. Now the view draws that one list and the
input code indexes it, so they cannot disagree.

### Why it is built this way

**The reasoning is not in the comments — it is in
[`docs/adr/`](docs/adr/README.md)**, one file per decision, referenced from the
code by id (`// ADR-0018`). The code carries the tripwires; the ADRs carry the
arguments. They are append-only: a decision that changes is superseded rather
than edited, so a stale ADR is history instead of a lie.

Start with `0001`–`0004` — the decisions that look like bugs and have each been
"fixed" at least once. If you are wondering why the screen never animates, why
both cues feel the same, why there is no session timer, or why Back does not go
back, they are all in there.

`just check-adrs` fails the build on a dangling reference or an ADR nothing
points at.

## Reference

- Persistent values: <https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html>
- Input behaviour: <https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html>
- The shared Back behaviour, on Garmin's forum: <https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-swipe-right-on-the-left-side-of-the-screen-triggers-onkey-key_esc>
