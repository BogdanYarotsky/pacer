import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

class pacerApp extends Application.AppBase {
    // Shown on the main screen so the build running on the watch is
    // identifiable at a glance. Bump on every sideload.
    const APP_VERSION = "0.13";

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

    var _timer = null;
    var _paceHundredths = DEFAULT_PACE_HUNDREDTHS;
    var _vibeStrength = DEFAULT_VIBE_STRENGTH;
    var _vibeDuration = DEFAULT_VIBE_DURATION;

    function initialize() {
        AppBase.initialize();
        loadSettings();
    }

    function onStart(state as Dictionary?) as Void {
        startTimer();
    }

    function timerCallback() as Void {
        if (_vibeStrength == 0 || !(Attention has :vibrate)) {
            return;
        }

        var vibe = [
            new Attention.VibeProfile(_vibeStrength, _vibeDuration)
        ];
        Attention.vibrate(vibe);
    }

    function onStop(state as Dictionary?) as Void {
        stopTimer();
    }

    function startTimer() as Void {
        stopTimer();
        _timer = new Timer.Timer();
        _timer.start(method(:timerCallback), getIntervalMilliseconds(), true);
    }

    function stopTimer() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new pacerView(), new pacerDelegate() ];
    }

    function getPaceHundredths() {
        return _paceHundredths;
    }

    function getVibrationStrength() {
        return _vibeStrength;
    }

    function getVibrationDuration() {
        return _vibeDuration;
    }

    // Each breath has two cues: one at each inhale/exhale boundary.
    function getIntervalMilliseconds() {
        return ((3000000.0 / _paceHundredths) + 0.5).toNumber();
    }

    function getPaceText() {
        return formatHundredths(_paceHundredths) + " breaths/min";
    }

    function getIntervalText() {
        var secondsHundredths = ((getIntervalMilliseconds() / 10.0) + 0.5).toNumber();
        return "Pulse every " + formatHundredths(secondsHundredths) + " s";
    }

    function getStrengthText() {
        return _vibeStrength.toString() + "%";
    }

    function getDurationText() {
        return _vibeDuration.toString() + " ms";
    }

    function setPaceHundredths(value) as Void {
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

    function setVibrationStrength(value) as Void {
        if (value < MIN_VIBE_STRENGTH || value > MAX_VIBE_STRENGTH) {
            return;
        }

        _vibeStrength = value;
        Storage.setValue(STRENGTH_STORAGE_KEY, value);
        WatchUi.requestUpdate();
    }

    function setVibrationDuration(value) as Void {
        if (value < MIN_VIBE_DURATION || value > MAX_VIBE_DURATION) {
            return;
        }

        _vibeDuration = value;
        Storage.setValue(DURATION_STORAGE_KEY, value);
        WatchUi.requestUpdate();
    }

    private function loadSettings() as Void {
        var storedPace = Storage.getValue(PACE_STORAGE_KEY);
        if (storedPace instanceof Number &&
                storedPace >= MIN_PACE_HUNDREDTHS &&
                storedPace <= MAX_PACE_HUNDREDTHS) {
            _paceHundredths = storedPace;
        }

        var storedStrength = Storage.getValue(STRENGTH_STORAGE_KEY);
        if (storedStrength instanceof Number &&
                storedStrength >= MIN_VIBE_STRENGTH &&
                storedStrength <= MAX_VIBE_STRENGTH) {
            _vibeStrength = storedStrength;
        }

        var storedDuration = Storage.getValue(DURATION_STORAGE_KEY);
        if (storedDuration instanceof Number &&
                storedDuration >= MIN_VIBE_DURATION &&
                storedDuration <= MAX_VIBE_DURATION) {
            _vibeDuration = storedDuration;
        }
    }

    private function formatHundredths(value) {
        var whole = (value / 100).toNumber();
        var fraction = value % 100;
        var fractionText = fraction.toString();

        if (fraction < 10) {
            fractionText = "0" + fractionText;
        }

        return whole.toString() + "." + fractionText;
    }
}

function getApp() as pacerApp {
    return Application.getApp() as pacerApp;
}
