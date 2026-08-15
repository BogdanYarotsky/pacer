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
assessment protocols sweep. The default of 5.71 is a personally measured
resonance frequency, not a generic value; re-measure and adjust it on the watch
rather than in code. The 0.01 step is finer than any published protocol resolves
to — they use 0.5 steps, 0.2 in refined variants — because the range is walked by
nudging a known value, not by sweeping it.

## Using it

The single screen shows the time, three editable settings and the running build.
Nothing on it changes on its own except the clock, once a minute:

```
                    07:42

        ( − )      PACE            ( + )
                   5.71 BPM / 5.25s

        ( − )      STRENGTH        ( + )
                   15%

        ( − )      LENGTH          ( + )
                   170 ms

                    v0.22
```

| Setting | Default | Range | Step per tap |
| --- | ---: | ---: | ---: |
| Breathing pace | 5.71 breaths/min | 4.50–7.00 | 0.01 |
| Vibration strength | 15% | 1–100% | 2% |
| Vibration length | 170 ms | 20–1000 ms | 10 ms |

Tap the `−` and `+` circles to change a value. The centre text is deliberately
inert, so reading a value can never change it. Values are written to
`Application.Storage` immediately and survive app restarts.

**There is no mute.** Strength bottoms out at 1%, not 0%, because the useful
question at the bottom of the scale is "can I still feel this?" and silence
cannot answer it. Both floors sit deliberately *below* what a wrist is likely to
register, so the threshold is somewhere you can find rather than somewhere the
range hides:

- `VibeProfile.dutyCycle` is documented as 0–100%, so 1–100% is the entire API
  range minus silence. A rotating-mass actuator has a duty cycle below which it
  does not turn at all — often quoted near 30% for PWM drive — so expect a dead
  band at the bottom that is the motor's, not the app's.
- `VibeProfile.length` has **no documented bounds** in the SDK at either end;
  20–1000 ms is entirely this app's choice. Published vibrotactile work puts the
  shortest perceivable pulse near 30 ms and rhythmic patterns nearer 50 ms, and
  actuator rise time is the harder limit at 50–100 ms to full amplitude.

None of that is verifiable from a computer: `Attention.vibrate` does nothing
observable in the simulator. Sweep it on your own wrist.

**Upper button — touch lock.** Pressing the upper physical button toggles a
global touch lock. Locked, the `−`/`+` controls dim and taps do nothing; that
dimming is the whole of the state display, and the screen no longer says so in
words as well. This exists because a sleeve or a palm across the screen can
trigger a platform-level exit that never reaches the app at all. Lock it before a
session; the upper button still unlocks.

**Lower button — Back.** Unlocked, Back exits. Locked, Back unlocks and stays
put, so during a session — when you are locked anyway — it takes two presses to
leave, and the first one visibly brightens the controls.

Pacer will not exit while the touch lock is engaged, because
`configureTouchEvents({ :enabled => false })` is a *watch-global* setting that
can outlive the app and leave the whole watch untouchable until it is rebooted.
Being unlocked is exactly the condition that makes leaving safe, so that one flag
is the entire guard — no confirmation window, no timers. If unlocking is
rejected, Pacer stays open and stays locked.

A right swipe is the same event as the lower button as far as the API is
concerned, so it is swallowed rather than treated as Back — see the input notes
in `AGENTS.md`.

**The version on screen is the point.** A sideload to this watch goes over MTP
and *cannot* be verified from the host — see the deploy section of `AGENTS.md`.
Reading the version off the watch is the only proof of which build is running,
which is why `just deploy` bumps it before every build.

## Build and run

Everything goes through `just`; see `AGENTS.md` for the full recipe list and for
the toolchain versions this is pinned to.

```
just build      # compile for vivoactive5 at strict typecheck (-w -l 3)
just test       # build with -t, run the unit tests in the simulator, fail loudly
just sim        # launch the simulator and load the app
just shot       # capture the simulator window to shots/vivoactive5.png
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
| `source/pacerDelegate.mc` | Input, the touch lock, and when Back may exit |
| `source/MainInputGate.mc` | Tells a physical button from a touch gesture |
| `source/TouchControl.mc` | The watch-global touch switch, and its failure modes |
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
