# Pacer for vívoactive 5

Pacer is a resonance-frequency breathing pacer. It vibrates twice per breathing
cycle — once at each turn-around — and does nothing else. There is one screen and
no menus. The cue is haptic and always will be; there is no visual pacing
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

The pace range is 4.50–7.00 breaths/min, the band standard resonance-frequency
assessment protocols sweep. It starts at **6.00** — 0.1 Hz, the population
average the literature converges on — because that is where to start looking, not
an answer. Resonance frequency is individual: measure your own and dial it in on
the watch rather than in code. The 0.01 step is finer than any published protocol
resolves to — they use 0.5 steps, 0.2 in refined variants — because the range is
walked by nudging a known value, not by sweeping it.

## Using it

The single screen shows the time, three editable settings and the running build.
Nothing on it changes on its own except the clock, once a minute:

```
                    07:42

        ( − )      POWER           ( + )
                   20%

        ( − )      PACE            ( + )
                   6bpm | 5s

        ( − )      BUZZ            ( + )
                   100ms

                    v0.22
```

| Setting | Default | Range | Step per tap |
| --- | ---: | ---: | ---: |
| Vibration strength — the `POWER` row | 20% | 2–100% | 2% |
| Breathing pace — the `PACE` row | 6.00 breaths/min | 4.50–7.00 | 0.01 |
| Vibration length — the `BUZZ` row | 100 ms | 10–250 ms | 10 ms |

`PACE` leads with breaths per minute — the number a tap moves, and the one
resonance-frequency protocols are written in — and carries the cue interval
beside it past a divider, because that is the half you can check against a clock:
count one gap between buzzes and you know the setting is what you think it is.
The interval is half a breath, since there are two cues per breath.

Trailing zeros are dropped on both numbers to cut clutter, so 6.00 reads
`6 bpm (5s)`. The line therefore changes width as you tap through it, and being
centred it shifts under the thumb rather than growing to one side. Seconds are
written `s` rather than `sec` because the spelled-out version is wider than the
gap between the two circles and drew straight through them.

`POWER` and `BUZZ` each step by their own unit, and every range divides evenly by
its step, so both endpoints are exactly reachable: 24 taps walk the buzz length
end to end, 49 the power scale.

Tap the `−` and `+` circles to change a value. The centre text is deliberately
inert, so reading a value can never change it. Values are written to
`Application.Storage` immediately and survive app restarts.

**There is no mute.** Strength bottoms out at 2%, not 0%, because the useful
question at the bottom of the scale is "can I still feel this?" and silence
cannot answer it. Both floors sit deliberately *below* what a wrist is likely to
register, so the threshold is somewhere you can find rather than somewhere the
range hides:

- `VibeProfile.dutyCycle` is documented as 0–100%, so the scale is the entire API
  range minus silence, walked in even steps: 2, 4, … 100. A rotating-mass
  actuator has a duty cycle below which it does not turn at all — often quoted
  near 30% for PWM drive — so expect a dead band at the bottom that is the
  motor's, not the app's.
- `VibeProfile.length` has **no documented bounds** in the SDK at either end;
  10–250 ms is entirely this app's choice. Published vibrotactile work puts the
  shortest perceivable pulse near 30 ms and rhythmic patterns nearer 50 ms, and
  actuator rise time is the harder limit at 50–100 ms to full amplitude. The
  ceiling is 250 because a pulse long enough to be felt as a buzz rather than a
  tick has stopped being a metronome beat, and use in practice stays under
  ~200 ms.

None of that is verifiable from a computer: `Attention.vibrate` does nothing
observable in the simulator. Sweep it on your own wrist.

**Locking the screen is the watch's job, not Pacer's.** Hold the upper button →
controls → **Lock Screen**. It works inside a running app, and it locks the
buttons as well as the touchscreen, so nothing — a sleeve, a palm, a knock
against a doorframe — can reach Pacer while you breathe. Unlock the same way.

Do that before a session. Without it, a palm across the screen can trigger a
platform-level exit that Pacer never sees and cannot prevent.

Pacer had its own touch lock once, built on
`configureTouchEvents({ :enabled => false })`. It worked, but that setting is
*watch-global* and outlives the app: when restoring it failed, the whole watch
was left without touch until it was rebooted — and Pacer could not repair it,
because relaunching Pacer needs touch to reach the app list. The watch's own lock
has none of that failure mode, because the OS owns the state and restores it.

**Upper button — nothing.** It used to toggle Pacer's lock. Held, it opens the
controls menu, which is where Lock Screen lives.

**Lower button — Back. It exits, immediately.** There is no confirmation, because
there is nothing left to clean up before leaving. Lock the screen during a
session and the button cannot reach Pacer anyway.

A right swipe arrives as the same event as the lower button, so Pacer tells them
apart and swallows the swipe — see the input notes in `AGENTS.md`.

**If the bottom line reads `VIBE OFF`, the watch cannot vibrate** — either the
system vibration setting is off or the device has no motor. Pacer will run a
flawless session and you will feel nothing, so it says so rather than leaving you
to tell that apart from a dead app. It is the only warning on the screen.

**The version on screen is the point — on a sideload.** A sideload to this watch
goes over MTP and *cannot* be verified from the host — see the deploy section of
`AGENTS.md`. Reading the version off the watch is the only proof of which build
is running, which is why `just deploy` bumps it before every build.

A Store install has no such problem: the Connect IQ app reports the installed
version. So the version line is drawn in **debug builds only**, which is every
sideload. In a release build the bottom of the screen is empty unless something
is wrong — the only thing that can appear there is `VIBE OFF`.

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

Garmin's own setup guides:

- <https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/>
- <https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/>
- <https://developer.garmin.com/connect-iq/core-topics/security/> (developer keys)

### Installing on the watch

`just deploy` bumps `APP_VERSION`, builds, and copies the PRG to `GARMIN\APPS`
over MTP. Then launch Pacer on the watch and check the version on screen against
what the script printed. If it shows an older version, the watch is still running
the old build.

A differently signed build with the same app id must be uninstalled from the
watch first — and that wipes the stored pace, strength and length.

## How the source is organised

Anything that can be a pure function is one, so it can be unit tested without a
running app, a graphics context or a simulator window.

| File | Responsibility |
| --- | --- |
| `source/pacerApp.mc` | Settings, storage, the cue timer, app lifecycle |
| `source/pacerView.mc` | The only screen — draws, decides nothing |
| `source/pacerDelegate.mc` | Input — telling a button press from a touch |
| `source/MainInputGate.mc` | Tells a physical button from a touch gesture |
| `source/Layout.mc` | Every coordinate, including round-screen chord maths |
| `source/Display.mc` | Every string the screen draws |
| `source/PacerMath.mc` | Pace arithmetic, clamping and value formatting |
| `source/ClockText.mc` | Clock rendering, 12- and 24-hour |

`Layout` and `Display` exist so the tests measure the real coordinates and the
real strings. A literal pixel offset or caption in `pacerView.mc` puts it beyond
the reach of the test that is supposed to cover it — both classes of drift have
shipped here before.

## Reference

- Persistent values: <https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html>
- Input behaviour: <https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html>
- The shared Back behaviour, on Garmin's forum: <https://forums.garmin.com/developer/connect-iq/i/bug-reports/bug-swipe-right-on-the-left-side-of-the-screen-triggers-onkey-key_esc>
