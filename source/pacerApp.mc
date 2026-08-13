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
    const DEFAULT_VIBE_STRENGTH = 15;
    const DEFAULT_VIBE_DURATION = 170;

    // Adult resonance frequency falls within 4.5-6.5 breaths/min.
    const MIN_PACE_HUNDREDTHS = 450;
    const MAX_PACE_HUNDREDTHS = 650;

    // VibeProfile.dutyCycle is documented as 0-100%, "0 indicating no vibration
    // and 100 indicating the strongest" -- so this range IS the full API range,
    // less the mute. The floor is 1 rather than 0 deliberately: the bottom of
    // the scale should be the weakest cue the hardware can attempt, not silence.
    //
    // Whether 1% produces anything a wrist can feel is NOT knowable from here.
    // Attention.vibrate does nothing observable in the simulator, and a rotating
    // -mass actuator has a minimum duty cycle below which it does not turn at
    // all -- commonly quoted around 30% for PWM drive. Finding the real floor is
    // a job for the watch; the point of starting at 1 is that the scale no
    // longer hides the bottom of it.
    const MIN_VIBE_STRENGTH = 1;
    const MAX_VIBE_STRENGTH = 100;

    // VibeProfile.length is documented only as "milliseconds" -- the SDK states
    // no bounds at either end, so this range is entirely our own choice.
    //
    // 20 ms is deliberately below anything a body can register, for the same
    // reason as the 1% floor: a range that starts at the threshold cannot tell
    // you where the threshold is. Published vibrotactile work puts the shortest
    // perceivable pulse around 30 ms, and rhythmic patterns need nearer 50 ms;
    // actuator rise time is the harder limit, 50-100 ms to reach full amplitude
    // on a rotating-mass motor. Expect the first genuinely felt step to be some
    // way above the floor.
    const MIN_VIBE_DURATION = 20;
    const MAX_VIBE_DURATION = 1000;

    // One step per tap of the corresponding edge control. These live here, not
    // in pacerDelegate, so the range and the step that walks it are declared
    // together -- a step that does not divide its range is how an endpoint
    // becomes unreachable.
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
    private var _touchLocked as Boolean = false;
    private var _exitPromptVisible as Boolean = false;

    // Rebuilt only when strength or duration changes, rather than allocated
    // afresh on every cue. At the default pace that is ~11 allocations a minute
    // for the entire length of a session.
    private var _vibeProfiles as Array<Attention.VibeProfile>? = null;

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

    function timerCallback() as Void {
        var minute = System.getClockTime().min;
        if (minute != _lastRedrawMinute) {
            _lastRedrawMinute = minute;
            WatchUi.requestUpdate();
        }

        // No mute branch: the strength floor is 1%, not 0%. The weakest setting
        // still asks the hardware for a cue, and whether one arrives is the
        // hardware's answer to give.
        if (!(Attention has :vibrate)) {
            return;
        }

        Attention.vibrate(vibeProfiles());
    }

    private function vibeProfiles() as Array<Attention.VibeProfile> {
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
        // Final best-effort cleanup for termination paths not initiated by the
        // main delegate. TouchControl contains the foreground exception.
        TouchControl.setEnabled(true);
        stopTimer();
    }

    // API 4.2.3, supported by vivoactive5 (API 5.2.0). The callback runs when
    // the app is hidden, so restoration may be rejected; it remains a safe
    // best-effort fallback for system-driven background transitions.
    function onInactive(state as Dictionary?) as Void {
        TouchControl.setEnabled(true);
    }

    function onActive(state as Dictionary?) as Void {
        applyTouchLock();
        WatchUi.requestUpdate();
    }

    // Each breath has two cues, one at each inhale/exhale boundary, so the timer
    // period is half a breath. The arithmetic lives in PacerMath so it is
    // testable without an application instance -- see tests/PacerMathTest.mc.
    function startTimer() as Void {
        stopTimer();
        var timer = new Timer.Timer();
        timer.start(method(:timerCallback), PacerMath.intervalMillis(_paceHundredths), true);
        _timer = timer;
    }

    function stopTimer() as Void {
        var timer = _timer;
        if (timer != null) {
            timer.stop();
            _timer = null;
        }
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

    function isTouchLocked() as Boolean {
        return _touchLocked;
    }

    function setTouchLocked(locked as Boolean) as Boolean {
        if (!TouchControl.setEnabled(!locked)) {
            return false;
        }

        _touchLocked = locked;
        WatchUi.requestUpdate();
        return true;
    }

    function applyTouchLock() as Boolean {
        return TouchControl.setEnabled(!_touchLocked);
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

    function isExitPromptVisible() as Boolean {
        return _exitPromptVisible;
    }

    function setExitPromptVisible(visible as Boolean) as Void {
        if (_exitPromptVisible != visible) {
            _exitPromptVisible = visible;
            WatchUi.requestUpdate();
        }
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
