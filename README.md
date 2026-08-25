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
**Yudemon** and **Elite HRV** — run an assessment there, take the breathing
rate it settles on, and convert it once: seconds between cues = 60 / bpm / 2.
A measured 5.5 breaths/min, for example, dials in as `EVERY 5.45s`.

## Using it

The main screen shows the time, the two settings you actually reach for during a
session, and the charge left. Only two things on it change on their own — the
clock and the battery — and both are repainted once a minute:

```
                    07:42


        (−)      POWER 20%       (+)


        (−)      PULSE 100ms     (+)


                  BATT 80%
```

The bottom line shows the charge left, `VIBE OFF` if the watch cannot vibrate,
or `HOLD TO EXIT` for two seconds after you press Back.

**Press the upper button for the interval.** It is the one setting you measure
once and then leave alone, so it lives on a screen of its own rather than costing
the other two a third of the glass. Press the upper button again, or Back, or
swipe right, to return.

```


        (−)      EVERY 5s        (+)


                    v0.24
```

| Setting | Where | Default | Range | Step per tap |
| --- | --- | ---: | ---: | ---: |
| Vibration strength — the `POWER` row | main | 20% | 1–100% | 5%, and 1% at 5% and below |
| Vibration length — the `PULSE` row | main | 100 ms | 10–250 ms | 10 ms |
| Seconds between cues — the `EVERY` row | upper button | 5.00 s | 0.05–15 s | 0.05 s |

`EVERY` is the number the timer runs, exposed with no translation: one buzz
every that many seconds. It is half a breath, since there are two cues per
breath — and you can check it against any clock by counting one gap between
buzzes. The 0.05 s floor is the platform timer's own minimum, not a design
opinion; the 15 s ceiling — 30 s per breath — is far past any breathing
practice. The range is deliberately much wider than the adult resonance band:
children pace faster, and a bare interval repurposes as a plain haptic
metronome.

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

**Upper button — the interval.** Press it to open the `EVERY` screen and press it
again to close. Held, it opens the watch's controls menu, which is where Lock
Screen lives — a hold, not a press, so the two do not collide.

**Lower button — Back, and it never exits.** On the `EVERY` screen it goes back
to the main screen. On the main screen it does nothing except show
`HOLD TO EXIT` for two seconds. Same for a right swipe, which arrives as the
identical event.

**To quit, hold the lower button.** From either screen.

That looks like an odd choice and it is not one — it is forced. On this watch the
firmware **synthesises a real button press for a right swipe**, so nothing in the
app can tell your thumb from a sleeve brushing the glass, and Candle used to end
sessions because of it. Six breadcrumbs off a wrist say so; the full working is
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

**The version on screen is the point — on a sideload.** A sideload to this watch
goes over MTP and *cannot* be verified from the host — see the deploy section of
`AGENTS.md`. Reading the version off the watch is the only proof of which build
is running, which is why `just deploy` bumps it before every build. It sits at
the bottom of the **`EVERY` screen**, one button press away: you read it once
after a deploy and never again while breathing.

A Store install has no such problem: the Connect IQ app reports the installed
version. So the version is drawn in **debug builds only**, which is every
sideload; on a Store install the `EVERY` screen carries its one row and nothing
else. Release builds once drew a small candle mark at the bottom of the main
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
just deploy     # bump the on-screen version, build, push to the watch over MTP
just input-test # drive real taps and button presses into the simulator (~40s)
```

`just build` and `just test` are the loop. Nothing is finished until both pass.

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
| `source/ExitForensics.mc` | Debug-only exit breadcrumb for the phantom-swipe diagnosis |

`Layout` and `Display` exist so the tests measure the real coordinates and the
real strings. A literal pixel offset or caption in `candleView.mc` puts it beyond
the reach of the test that is supposed to cover it — both classes of drift have
shipped here before.

`Rows` exists for the same kind of reason. A screen's row order used to be
written down twice, once in the tap map and once in the draw calls, and if the
two disagreed everything still compiled and every tap silently edited a different
setting than the one under your thumb. Now the view draws that one list and the
input code indexes it, so they cannot disagree.

## Reference

- Persistent values: <https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html>
- Input behaviour: <https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html>
- The shared Back behaviour, on Garmin's forum: <https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-swipe-right-on-the-left-side-of-the-screen-triggers-onkey-key_esc>
