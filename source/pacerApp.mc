import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

class pacerApp extends Application.AppBase {
    // Shown on the main screen so the build running on the watch is
    // identifiable at a glance. Bump on every sideload.
    const APP_VERSION = "0.22";

    const DEFAULT_PACE_HUNDREDTHS = 571;

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

    // Adult resonance frequency falls within 4.5-7.0 breaths/min, which is the
    // band standard assessment protocols sweep (4.5, 5.0 ... 7.0). The ceiling
    // was 6.5 for a while and simply could not express the top of that band.
    //
    // The 0.01 step is finer than any published protocol resolves to -- they use
    // 0.5 steps, 0.2 in refined variants -- because the default here came from an
    // individual measurement at that resolution, and the range is walked by
    // nudging a known value rather than sweeping it. The precision is real all
    // the way down: all 251 values map to distinct timer periods, the closest
    // pair 6 ms apart, so no two paces silently collapse to the same cue.
    const MIN_PACE_HUNDREDTHS = 450;
    const MAX_PACE_HUNDREDTHS = 700;

    // VibeProfile.dutyCycle is documented as 0-100%, "0 indicating no vibration
    // and 100 indicating the strongest" -- so this range IS the full API range,
    // less the mute. The floor is above 0 deliberately: the bottom of the scale
    // should be the weakest cue the hardware can attempt, not silence.
    //
    // It is 2 and not the 1 it was because STRENGTH_STEP is 2. A floor of 1 put
    // the entire scale on odd percents and left the floor standing beside its own
    // ladder; at 2 the scale is exactly the fifty even percents, floor and
    // ceiling included. Nothing is lost at the bottom -- 1% against 2% is not a
    // distinction a wrist was ever going to make.
    //
    // Whether 2% produces anything a wrist can feel is NOT knowable from here.
    // Attention.vibrate does nothing observable in the simulator, and a rotating
    // -mass actuator has a minimum duty cycle below which it does not turn at
    // all -- commonly quoted around 30% for PWM drive. Finding the real floor is
    // a job for the watch; the point of starting this low is that the scale no
    // longer hides the bottom of it.
    const MIN_VIBE_STRENGTH = 2;
    const MAX_VIBE_STRENGTH = 100;

    // VibeProfile.length is documented only as "milliseconds" -- the SDK states
    // no bounds at either end, so this range is entirely our own choice.
    //
    // 10 ms is deliberately below anything a body can register, for the same
    // reason as the 2% floor: a range that starts at the threshold cannot tell
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
    // in pacerDelegate, so the range and the step that walks it are declared
    // together -- a step that does not divide its range is how an endpoint
    // becomes unreachable. All three divide evenly, and the defaults sit on their
    // own ladders; settingsRangesAndStepsAreCoherent asserts both.
    const PACE_STEP = 1;
    const STRENGTH_STEP = 2;
    const DURATION_STEP = 10;

    const PACE_STORAGE_KEY = "paceHundredths";
    const STRENGTH_STORAGE_KEY = "vibrationStrength";
    const DURATION_STORAGE_KEY = "vibrationDuration";

    private var _timer as Timer.Timer? = null;
    private var _paceHundredths as Number = DEFAULT_PACE_HUNDREDTHS;
    private var _vibeStrength as Number = DEFAULT_VIBE_STRENGTH;
    private var _vibeDuration as Number = DEFAULT_VIBE_DURATION;

    // Rebuilt only when strength or duration changes, rather than allocated
    // afresh on every cue. At the default pace that is ~11 allocations a minute
    // for the entire length of a session.
    private var _vibeProfiles as Array<Attention.VibeProfile>? = null;

    // What startTimer last started the cue at. See getTimerPeriodMillis.
    private var _timerPeriodMillis as Number = 0;

    // The clock is the only thing on screen the cue timer can change, and it
    // changes once a minute. Redrawing on every cue would repaint the whole
    // display ~11 times a minute to show the same pixels. Every other change
    // requests its own update, so this gates the timer's redraw alone.
    private var _lastRedrawMinute as Number = -1;

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
    // No mute branch: the strength floor is 2%, not 0%. The weakest setting
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
    }

    // The clock can be a whole minute stale by the time the app comes back to
    // the foreground, so redraw rather than wait for the next cue.
    function onActive(state as Dictionary?) as Void {
        WatchUi.requestUpdate();
    }

    // Each breath has two cues, one at each inhale/exhale boundary, so the timer
    // period is half a breath. The arithmetic lives in PacerMath so it is
    // testable without an application instance -- see tests/PacerMathTest.mc.
    function startTimer() as Void {
        stopTimer();
        var period = PacerMath.intervalMillis(_paceHundredths);
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
        return [ new pacerView(), new pacerDelegate() ];
    }

    function getPaceHundredths() as Number {
        return _paceHundredths;
    }

    function getVibrationStrength() as Number {
        return _vibeStrength;
    }

    function getVibrationDuration() as Number {
        return _vibeDuration;
    }

    function getPaceText() as String {
        return PacerMath.formatPaceSummary(_paceHundredths);
    }

    function getStrengthText() as String {
        return PacerMath.formatStrength(_vibeStrength);
    }

    function getDurationText() as String {
        return PacerMath.formatDuration(_vibeDuration);
    }

    // The setters clamp through PacerMath.clamp rather than reject an
    // out-of-range value -- see the reasoning there. The unchanged guard is what
    // that clamping makes necessary: without it, every tap on "+" at the maximum
    // would rewrite Storage and restart the cue timer to no effect.

    function setPaceHundredths(value as Number) as Void {
        var next = PacerMath.clamp(value, MIN_PACE_HUNDREDTHS, MAX_PACE_HUNDREDTHS);
        if (next == _paceHundredths) {
            return;
        }

        _paceHundredths = next;
        Storage.setValue(PACE_STORAGE_KEY, next);

        if (_timer != null) {
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    function setVibrationStrength(value as Number) as Void {
        var next = PacerMath.clamp(value, MIN_VIBE_STRENGTH, MAX_VIBE_STRENGTH);
        if (next == _vibeStrength) {
            return;
        }

        _vibeStrength = next;
        _vibeProfiles = null;
        Storage.setValue(STRENGTH_STORAGE_KEY, next);
        WatchUi.requestUpdate();
    }

    function setVibrationDuration(value as Number) as Void {
        var next = PacerMath.clamp(value, MIN_VIBE_DURATION, MAX_VIBE_DURATION);
        if (next == _vibeDuration) {
            return;
        }

        _vibeDuration = next;
        _vibeProfiles = null;
        Storage.setValue(DURATION_STORAGE_KEY, next);
        WatchUi.requestUpdate();
    }

    private function loadSettings() as Void {
        _paceHundredths = readStoredNumber(
            PACE_STORAGE_KEY, MIN_PACE_HUNDREDTHS, MAX_PACE_HUNDREDTHS, DEFAULT_PACE_HUNDREDTHS);
        _vibeStrength = readStoredNumber(
            STRENGTH_STORAGE_KEY, MIN_VIBE_STRENGTH, MAX_VIBE_STRENGTH, DEFAULT_VIBE_STRENGTH);
        _vibeDuration = readStoredNumber(
            DURATION_STORAGE_KEY, MIN_VIBE_DURATION, MAX_VIBE_DURATION, DEFAULT_VIBE_DURATION);
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

function getApp() as pacerApp {
    return Application.getApp() as pacerApp;
}
