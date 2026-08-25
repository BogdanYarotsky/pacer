import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

class candleApp extends Application.AppBase {
    // Drawn at the bottom of the SETTINGS screen -- one press of the upper
    // button -- in debug builds only, so the build running on the watch is
    // identifiable after a sideload. It is off the main screen deliberately:
    // you read it once after a deploy and never again while breathing.
    // deploy.ps1 bumps this on every sideload and its closing message tells
    // you where to look; the two have to move together.
    const APP_VERSION = "0.27";

    // One cue every 5.00 s -- 10 s per breath, 0.1 Hz, the Lehrer resonance
    // protocol's canonical frequency and the value the literature converges on
    // as a population average.
    //
    // It is deliberately NOT a measured value. A default is what a watch that
    // has never been configured starts at, and one person's resonance frequency
    // dressed as a default would be a wrong number wearing a right number's
    // clothes. Whoever installs this should measure their own and dial it in;
    // 5.00 s is the place to start looking, not an answer.
    const DEFAULT_EVERY_HUNDREDTHS = 500;

    // Both vibe defaults sit on their own ladders -- settingsRangesAndStepsAre
    // Coherent proves it -- and both are starting points for a wrist to move
    // from, not values derived from anything here. Where they land against the
    // figures quoted with each range below: 100 ms is the top of the 50-100 ms a
    // rotating-mass actuator needs to reach full amplitude, and 20% is under the
    // ~30% duty cycle commonly quoted for PWM drive -- as every default this app
    // has shipped has been, which is fair evidence that figure does not bind on
    // this watch.
    const DEFAULT_VIBE_STRENGTH = 20;
    const DEFAULT_VIBE_DURATION = 100;

    // The interval, in hundredths of a second between cues -- and the pace
    // range below it, which is THE SAME RANGE IN THE OTHER UNIT. Read the two
    // together; neither is free to move on its own.
    //
    // CandleMath.paceToEvery maps each onto the other exactly, both endpoints
    // landing without rounding (300000/1000 = 300, 300000/200 = 1500). That is
    // the property the PACE row rests on: there is no interval the pace row
    // cannot show and no pace the interval row cannot. Break it and one of the
    // two rows acquires a state its controls cannot leave.
    //
    // The ceiling is unchanged: 15.00 s between cues -- 30 s per breath -- is
    // comfortably past any breathing practice.
    //
    // **The floor moved from 0.05 s to 3.00 s when PACE arrived**, and this is
    // the first time it was ever chosen. It used to be technical: 0.05 s is the
    // platform's documented Timer minimum, inherited rather than decided. Two
    // things set it at 3.00:
    //
    //   * A 0.1 bpm tap only moves the stored interval if 3000/b^2 >= 1, i.e.
    //     while b <= 17.3 bpm. Above that, adjacent rungs round to the same
    //     hundredth and the control silently does nothing -- 25.0 and 25.1 bpm
    //     both store 120. At the 10 bpm ceiling every rung is still 3
    //     hundredths clear, which is three times the margin it needs.
    //   * Nobody paces breathing above 10 bpm. The documented resonance bands
    //     are 4.5-7.0 for adults and 6.5-9.5 for children (Lehrer/Vaschillo);
    //     10-20 bpm is ordinary resting respiration, which wants no metronome.
    //
    // What it costs is the sub-3-second haptic metronome, which was a side
    // effect of the Timer minimum and not a capability anyone asked for. It
    // also means a watch holding an interval under 3.00 s falls back to the
    // default on the next launch -- readStoredNumber range-checks before it
    // trusts a stored value, and 0.05-2.99 s is below any breathing practice.
    const MIN_EVERY_HUNDREDTHS = 300;
    const MAX_EVERY_HUNDREDTHS = 1500;

    // The same setting in hundredths of a breath per minute: the exact
    // reciprocal image of the interval range above, and the range the PACE row
    // clamps in.
    //
    // Clamping happens in THIS unit and then converts -- see setPaceHundredths
    // -- because clamping after the conversion would let a pace step land on an
    // interval that sits on no bpm rung, and the row would stop being
    // reversible.
    //
    // 0.1 bpm per tap is five times finer than the assessment protocols that
    // produce these numbers: Lehrer and Vaschillo walk 6.5 down to 4.5 bpm in
    // 0.5-bpm steps. So any measured resonance frequency lands exactly on a
    // rung, with room to interpolate between the ones a protocol tests.
    const MIN_PACE_HUNDREDTHS = 200;
    const MAX_PACE_HUNDREDTHS = 1000;
    const PACE_STEP = 10;

    // VibeProfile.dutyCycle is documented as 0-100%, "0 indicating no vibration
    // and 100 indicating the strongest" -- so this range IS the full API range,
    // less the mute. The floor is above 0 deliberately: the bottom of the scale
    // should be the weakest cue the hardware can attempt, not silence.
    //
    // The taps do not walk this range evenly. POWER moves on a two-zone ladder
    // -- 5% steps over the working range, 1% steps at 5% and below (see
    // CandleMath.strengthUp/Down) -- so the floor is 1, the weakest request the
    // API can express, and the fine zone is there to find the hardware's real
    // threshold rather than step over it.
    //
    // Whether 1% produces anything a wrist can feel is NOT knowable from here.
    // Attention.vibrate does nothing observable in the simulator, and a rotating
    // -mass actuator has a minimum duty cycle below which it does not turn at
    // all -- commonly quoted around 30% for PWM drive. Finding the real floor is
    // a job for the watch; the point of starting this low is that the scale no
    // longer hides the bottom of it.
    const MIN_VIBE_STRENGTH = 1;
    const MAX_VIBE_STRENGTH = 100;

    // VibeProfile.length is documented only as "milliseconds" -- the SDK states
    // no bounds at either end, so this range is entirely our own choice.
    //
    // 10 ms is deliberately below anything a body can register, for the same
    // reason as the 1% floor: a range that starts at the threshold cannot tell
    // you where the threshold is. Published vibrotactile work puts the shortest
    // perceivable pulse around 30 ms, and rhythmic patterns need nearer 50 ms;
    // actuator rise time is the harder limit, 50-100 ms to reach full amplitude
    // on a rotating-mass motor. Expect the first genuinely felt step to be some
    // way above the floor.
    //
    // The ceiling is 250 ms, down from 1000. The top three quarters of that
    // range were reaching for nothing: use in practice stays under ~200 ms, and
    // a pulse long enough to be felt as a buzz rather than a tick has stopped
    // being a metronome beat. 250 keeps headroom over what gets used and makes
    // the whole scale 24 taps end to end instead of 98.
    const MIN_VIBE_DURATION = 10;
    const MAX_VIBE_DURATION = 250;

    // One step per tap of the corresponding edge control. These live here, not
    // in candleDelegate, so the range and the step that walks it are declared
    // together -- a step that does not divide its range is how an endpoint
    // becomes unreachable. Both divide evenly, and the defaults sit on their
    // own ladders; settingsRangesAndStepsAreCoherent asserts both. POWER has no
    // single step: its two-zone ladder lives in CandleMath.strengthUp/Down, and
    // the same test pins that ladder to this range's endpoints.
    const EVERY_STEP = 5;
    const DURATION_STEP = 10;

    // Storage keys are on-disk API: renaming one silently resets that setting
    // on every installed watch. everyHundredths is deliberately NOT the old
    // pace key re-worded -- the unit changed (hundredths of a second between
    // cues, was hundredths of a breath per minute), so it is a NEW key, and
    // migrateLegacyPace converts the old one exactly once.
    const EVERY_STORAGE_KEY = "everyHundredths";
    const STRENGTH_STORAGE_KEY = "vibrationStrength";
    const DURATION_STORAGE_KEY = "vibrationDuration";

    // The retired pace key and the band that build could actually write.
    // Anything stored outside it is not a pace value and is left alone.
    const LEGACY_PACE_STORAGE_KEY = "paceHundredths";
    const LEGACY_PACE_MIN = 450;
    const LEGACY_PACE_MAX = 700;

    private var _timer as Timer.Timer? = null;
    private var _everyHundredths as Number = DEFAULT_EVERY_HUNDREDTHS;
    private var _vibeStrength as Number = DEFAULT_VIBE_STRENGTH;
    private var _vibeDuration as Number = DEFAULT_VIBE_DURATION;

    // Rebuilt only when strength or duration changes, rather than allocated
    // afresh on every cue. At the default pace that is ~11 allocations a minute
    // for the entire length of a session.
    private var _vibeProfiles as Array<Attention.VibeProfile>? = null;

    // What startTimer last started the cue at. See getTimerPeriodMillis.
    private var _timerPeriodMillis as Number = 0;

    // The clock is the only thing on screen the cue timer needs to change, and
    // it changes once a minute. Redrawing on every cue would repaint the whole
    // display ~11 times a minute to show the same pixels. Every other change
    // requests its own update, so this gates the timer's redraw alone.
    //
    // The battery reading rides this same repaint for free -- it is drawn from
    // System.getSystemStats() inside onUpdate, so it refreshes whenever the
    // minute does and asks for nothing of its own.
    private var _lastRedrawMinute as Number = -1;

    // How long the "HOLD TO EXIT" hint stays on the bottom line after a Back.
    //
    // Back does not exit any more -- it cannot, because the firmware forges the
    // key event it would have to trust (see candleDelegate.onBack) -- so this
    // hint is the ONLY evidence the app noticed you pressed anything. Without
    // it a deliberate Back looks exactly like a frozen app.
    //
    // Two seconds is long enough to read four words and short enough that a
    // sleeve brushing the glass mid-session costs a glance, not a screen.
    const EXIT_HINT_MILLIS = 2000;

    // The app's THIRD and last timer -- the device allows three, and the cue
    // owns one while candleDelegate's hold-to-repeat owns another. It exists
    // only to take the hint back down; nothing else in the app is on a clock
    // that the cue does not already provide.
    private var _hintTimer as Timer.Timer? = null;
    private var _showExitHint as Boolean = false;

    function initialize() {
        AppBase.initialize();
        loadSettings();
    }

    function onStart(state as Dictionary?) as Void {
        startTimer();
    }

    // Buzz, and carry the clock. The cue is the only thing already ticking, so
    // it doubles as the clock's refresh rather than a second timer running
    // alongside it -- which also keeps the displayed minute at most one cue
    // interval (~5 s) stale, where a free-running 60 s timer would drift up to a
    // full minute behind the wall clock.
    //
    // No mute branch: the strength floor is 1%, not 0%. The weakest setting
    // still asks the hardware for a cue, and whether one arrives is the
    // hardware's answer to give.
    function timerCallback() as Void {
        var minute = System.getClockTime().min;
        if (minute != _lastRedrawMinute) {
            _lastRedrawMinute = minute;
            WatchUi.requestUpdate();
        }

        if (Attention has :vibrate) {
            Attention.vibrate(vibeProfiles());
        }
    }

    // The cue itself, exactly as timerCallback hands it to Attention.vibrate.
    //
    // Public rather than private so a test can read the profile the wrist will
    // feel, instead of the two numbers it was built from. Those numbers are
    // already covered everywhere; the cache between them and the motor is not,
    // and a cache that stopped being invalidated would leave the screen showing
    // a new value while the wrist kept feeling the old one.
    function vibeProfiles() as Array<Attention.VibeProfile> {
        var profiles = _vibeProfiles;
        if (profiles == null) {
            profiles = [
                new Attention.VibeProfile(_vibeStrength, _vibeDuration)
            ] as Array<Attention.VibeProfile>;
            _vibeProfiles = profiles;
        }
        return profiles;
    }

    function onStop(state as Dictionary?) as Void {
        stopTimer();
        stopHintTimer();
    }

    // The clock can be a whole minute stale by the time the app comes back to
    // the foreground, so redraw rather than wait for the next cue.
    function onActive(state as Dictionary?) as Void {
        WatchUi.requestUpdate();
    }

    // --- the exit hint ------------------------------------------------------
    //
    // Armed by a Back on the main screen, taken down by its own timer. The
    // state lives here rather than on the delegate because the view is what
    // draws it and the view already reads the app; parking it on the delegate
    // would mean the two screens' delegates each holding a piece of one fact.

    function armExitHint() as Void {
        stopHintTimer();
        _showExitHint = true;

        var timer = new Timer.Timer();
        timer.start(method(:hintCallback), EXIT_HINT_MILLIS, false);
        _hintTimer = timer;
        WatchUi.requestUpdate();
    }

    function showsExitHint() as Boolean {
        return _showExitHint;
    }

    function hintCallback() as Void {
        stopHintTimer();
        _showExitHint = false;
        WatchUi.requestUpdate();
    }

    private function stopHintTimer() as Void {
        var timer = _hintTimer;
        if (timer != null) {
            timer.stop();
            _hintTimer = null;
        }
    }

    // Each breath has two cues, one at each inhale/exhale boundary, so the timer
    // period is half a breath. The arithmetic lives in CandleMath so it is
    // testable without an application instance -- see tests/CandleMathTest.mc.
    function startTimer() as Void {
        stopTimer();
        var period = CandleMath.intervalMillis(_everyHundredths);
        var timer = new Timer.Timer();
        timer.start(method(:timerCallback), period, true);
        _timer = timer;
        _timerPeriodMillis = period;
    }

    function stopTimer() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
            _timer = null;
        }
        _timerPeriodMillis = 0;
    }

    // The period the running timer was started with, 0 when none is running.
    //
    // Timer.Timer does not report its own period, so without this there is no
    // way to assert the one thing a pace change has to do: restart the cue at
    // the new cadence. Only startTimer writes it, so a non-zero value here is
    // proof that startTimer ran -- see settingsVibeProfileTracksSettingChanges.
    function getTimerPeriodMillis() as Number {
        return _timerPeriodMillis;
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [
            new candleView(Rows.SCREEN_MAIN),
            new candleDelegate(Rows.SCREEN_MAIN)
        ];
    }

    function getEveryHundredths() as Number {
        return _everyHundredths;
    }

    function getVibrationStrength() as Number {
        return _vibeStrength;
    }

    function getVibrationDuration() as Number {
        return _vibeDuration;
    }

    // --- what a row shows, and what one tap does to it ----------------------
    //
    // Both are keyed by the row's identity and never by where it happens to be
    // drawn, so moving a setting to another screen is a one-line edit in Rows
    // and nothing else.
    //
    // They live here rather than in the delegate because everything a step
    // needs is already here: the range it clamps into, the stride it walks, and
    // the ladder POWER walks instead of a stride. The delegate used to hold a
    // six-armed if-chain over ACTION_ constants that named the settings, which
    // meant the one file that must not care which row is where was the file
    // that spelled it out. It now decodes a position and hands the identity
    // straight through.

    // Only the value is looked up here; how it renders is CandleMath.rowValueText,
    // which the layout sweep calls with values no watch is holding yet.
    function rowValueText(row as Number) as String {
        if (row == Rows.EVERY) {
            return CandleMath.rowValueText(row, _everyHundredths);
        }
        if (row == Rows.PACE) {
            return CandleMath.rowValueText(row, CandleMath.everyToPace(_everyHundredths));
        }
        if (row == Rows.PULSE) {
            return CandleMath.rowValueText(row, _vibeDuration);
        }
        return CandleMath.rowValueText(row, _vibeStrength);
    }

    // One tap of a row's "-" or "+". Every arm is deliberately unclamped: each
    // setter clamps, so a step off the end of a range is the no-op it should be
    // and the endpoint stays reachable from a value that is off the ladder.
    function stepRow(row as Number, increase as Boolean) as Void {
        if (row == Rows.EVERY) {
            setEveryHundredths(_everyHundredths + (increase ? EVERY_STEP : -EVERY_STEP));
        } else if (row == Rows.PACE) {
            // Stepped from the value ON THE GLASS, not from the stored
            // interval. everyToPace snaps to the nearest 0.1 bpm rung, so a
            // "+" always lands on the rung above the one being read, and a "-"
            // brings you back to it. Stepping from the raw interval instead
            // would make the pair irreversible the moment an EVERY tap left the
            // stored value between two rungs -- which it does constantly, since
            // the two ladders only line up at 7.75 bpm.
            //
            // "+" here SHORTENS the interval, where "+" on EVERY lengthens it.
            // More breaths per minute is less time between cues; reciprocal
            // units cannot agree on which way is up, and pretending otherwise
            // would mean a bpm row whose "+" lowered the bpm.
            setPaceHundredths(
                CandleMath.everyToPace(_everyHundredths) + (increase ? PACE_STEP : -PACE_STEP));
        } else if (row == Rows.PULSE) {
            setVibrationDuration(_vibeDuration + (increase ? DURATION_STEP : -DURATION_STEP));
        } else {
            setVibrationStrength(increase
                ? CandleMath.strengthUp(_vibeStrength)
                : CandleMath.strengthDown(_vibeStrength));
        }
    }

    // The setters clamp through CandleMath.clamp rather than reject an
    // out-of-range value -- see the reasoning there. The unchanged guard is what
    // that clamping makes necessary: without it, every tap on "+" at the maximum
    // would rewrite Storage and restart the cue timer to no effect.

    function setEveryHundredths(value as Number) as Void {
        var next = CandleMath.clamp(value, MIN_EVERY_HUNDREDTHS, MAX_EVERY_HUNDREDTHS);
        if (next == _everyHundredths) {
            return;
        }

        _everyHundredths = next;
        Storage.setValue(EVERY_STORAGE_KEY, next);

        if (_timer != null) {
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    // The PACE row's setter, and the only place in the app where the two units
    // meet.
    //
    // It clamps in BPM and converts afterwards, and that order is the whole
    // correctness argument: clamping in interval units would let a pace step
    // off the end of the range land on an interval that is on no bpm rung, and
    // the row would come back reading something the wearer never asked for.
    //
    // There is no Storage write here and no key of its own. PACE is a view on
    // everyHundredths -- one setting, two rows -- so this ends in the interval
    // setter and inherits its unchanged-guard, its write and its timer restart.
    // A pace change restarts the cue exactly as an interval change does, which
    // costs one breath and is the documented behaviour of both.
    function setPaceHundredths(value as Number) as Void {
        setEveryHundredths(CandleMath.paceToEvery(
            CandleMath.clamp(value, MIN_PACE_HUNDREDTHS, MAX_PACE_HUNDREDTHS)));
    }

    function setVibrationStrength(value as Number) as Void {
        var next = CandleMath.clamp(value, MIN_VIBE_STRENGTH, MAX_VIBE_STRENGTH);
        if (next == _vibeStrength) {
            return;
        }

        _vibeStrength = next;
        _vibeProfiles = null;
        Storage.setValue(STRENGTH_STORAGE_KEY, next);
        WatchUi.requestUpdate();
    }

    function setVibrationDuration(value as Number) as Void {
        var next = CandleMath.clamp(value, MIN_VIBE_DURATION, MAX_VIBE_DURATION);
        if (next == _vibeDuration) {
            return;
        }

        _vibeDuration = next;
        _vibeProfiles = null;
        Storage.setValue(DURATION_STORAGE_KEY, next);
        WatchUi.requestUpdate();
    }

    // Public rather than private for one reason: settingsMigratesLegacyPace can
    // only prove the migration by staging Storage and re-running this.
    function loadSettings() as Void {
        migrateLegacyPace();
        _everyHundredths = readStoredNumber(
            EVERY_STORAGE_KEY, MIN_EVERY_HUNDREDTHS, MAX_EVERY_HUNDREDTHS, DEFAULT_EVERY_HUNDREDTHS);
        _vibeStrength = readStoredNumber(
            STRENGTH_STORAGE_KEY, MIN_VIBE_STRENGTH, MAX_VIBE_STRENGTH, DEFAULT_VIBE_STRENGTH);
        _vibeDuration = readStoredNumber(
            DURATION_STORAGE_KEY, MIN_VIBE_DURATION, MAX_VIBE_DURATION, DEFAULT_VIBE_DURATION);
    }

    // Carry a wearer's measured pace across the unit change, exactly once.
    //
    // A valid value under the new key always wins -- once it exists, whatever
    // sits under the legacy key is dead data, never read again. Otherwise a
    // plausible legacy pace is converted and the legacy key deleted, so the
    // conversion cannot run twice and overwrite a later adjustment. An
    // implausible legacy value is not a pace and is left where it lies.
    private function migrateLegacyPace() as Void {
        var current = Storage.getValue(EVERY_STORAGE_KEY);
        if (current instanceof Number
                && current >= MIN_EVERY_HUNDREDTHS && current <= MAX_EVERY_HUNDREDTHS) {
            return;
        }

        var legacy = Storage.getValue(LEGACY_PACE_STORAGE_KEY);
        if (legacy instanceof Number
                && legacy >= LEGACY_PACE_MIN && legacy <= LEGACY_PACE_MAX) {
            Storage.setValue(EVERY_STORAGE_KEY, CandleMath.paceToEvery(legacy));
            Storage.deleteValue(LEGACY_PACE_STORAGE_KEY);
        }
    }

    // Storage.getValue returns a wide poly type, so the stored value is checked
    // for being a Number AND for being inside the supported range before it is
    // trusted. Anything else falls back to the default rather than propagating
    // a bad value into the timer.
    private function readStoredNumber(
        key as String,
        minimum as Number,
        maximum as Number,
        fallback as Number
    ) as Number {
        var stored = Storage.getValue(key);
        if (stored instanceof Number && stored >= minimum && stored <= maximum) {
            return stored;
        }
        return fallback;
    }

}

function getApp() as candleApp {
    return Application.getApp() as candleApp;
}
