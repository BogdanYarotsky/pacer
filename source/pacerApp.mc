import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

class pacerApp extends Application.AppBase {
    // Shown on the main screen so the build running on the watch is
    // identifiable at a glance. Bump on every sideload.
    const APP_VERSION = "0.20";

    const DEFAULT_PACE_HUNDREDTHS = 571;
    const DEFAULT_VIBE_STRENGTH = 15;
    const DEFAULT_VIBE_DURATION = 170;

    // Adult resonance frequency falls within 4.5-6.5 breaths/min.
    const MIN_PACE_HUNDREDTHS = 450;
    const MAX_PACE_HUNDREDTHS = 650;
    const MIN_VIBE_STRENGTH = 0;
    const MAX_VIBE_STRENGTH = 100;
    const MIN_VIBE_DURATION = 50;
    const MAX_VIBE_DURATION = 1000;

    const PACE_STORAGE_KEY = "paceHundredths";
    const STRENGTH_STORAGE_KEY = "vibrationStrength";
    const DURATION_STORAGE_KEY = "vibrationDuration";

    private var _timer as Timer.Timer? = null;
    private var _paceHundredths as Number = DEFAULT_PACE_HUNDREDTHS;
    private var _vibeStrength as Number = DEFAULT_VIBE_STRENGTH;
    private var _vibeDuration as Number = DEFAULT_VIBE_DURATION;
    private var _exitPromptVisible as Boolean = false;

    function initialize() {
        AppBase.initialize();
        loadSettings();
    }

    function onStart(state as Dictionary?) as Void {
        startTimer();
    }

    function timerCallback() as Void {
        // Repaint the current View often enough for the minute clock on the
        // pacing screen. This reuses the cue timer instead of consuming one of
        // the device's limited Timer slots.
        WatchUi.requestUpdate();

        if (_vibeStrength == 0 || !(Attention has :vibrate)) {
            return;
        }

        var vibe = [
            new Attention.VibeProfile(_vibeStrength, _vibeDuration)
        ] as Array<Attention.VibeProfile>;
        Attention.vibrate(vibe);
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

    function startTimer() as Void {
        stopTimer();
        var timer = new Timer.Timer();
        timer.start(method(:timerCallback), getIntervalMilliseconds(), true);
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

    // Each breath has two cues: one at each inhale/exhale boundary.
    // The arithmetic itself lives in PacerMath so it can be unit tested without
    // an application instance -- see tests/PacerMathTest.mc.
    function getIntervalMilliseconds() as Number {
        return PacerMath.intervalMillis(_paceHundredths);
    }

    function getPaceText() as String {
        return PacerMath.formatPaceSummary(_paceHundredths);
    }

    function getIntervalText() as String {
        var secondsHundredths = ((getIntervalMilliseconds() / 10.0) + 0.5).toNumber();
        return "Pulse every " + PacerMath.formatHundredths(secondsHundredths) + " s";
    }

    function getStrengthText() as String {
        return _vibeStrength.toString() + "%";
    }

    function isExitPromptVisible() as Boolean {
        return _exitPromptVisible;
    }

    function getExitPromptText() as String {
        return "Back again to exit";
    }

    function setExitPromptVisible(visible as Boolean) as Void {
        if (_exitPromptVisible != visible) {
            _exitPromptVisible = visible;
            WatchUi.requestUpdate();
        }
    }

    function getDurationText() as String {
        return _vibeDuration.toString() + " ms";
    }

    function setPaceHundredths(value as Number) as Void {
        if (value < MIN_PACE_HUNDREDTHS || value > MAX_PACE_HUNDREDTHS) {
            return;
        }

        _paceHundredths = value;
        Storage.setValue(PACE_STORAGE_KEY, value);

        if (_timer != null) {
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    function setVibrationStrength(value as Number) as Void {
        if (value < MIN_VIBE_STRENGTH || value > MAX_VIBE_STRENGTH) {
            return;
        }

        _vibeStrength = value;
        Storage.setValue(STRENGTH_STORAGE_KEY, value);
        WatchUi.requestUpdate();
    }

    function setVibrationDuration(value as Number) as Void {
        if (value < MIN_VIBE_DURATION || value > MAX_VIBE_DURATION) {
            return;
        }

        _vibeDuration = value;
        Storage.setValue(DURATION_STORAGE_KEY, value);
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
