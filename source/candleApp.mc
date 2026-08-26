import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

// State, persistence and the cue timer.
//
// A setting's range, the step that walks it and one tap's worth of change to it
// are all declared here together -- a step that does not divide its range is
// how an endpoint becomes unreachable. ADR-0026
class candleApp extends Application.AppBase {

    // Bumped by deploy.ps1 on every sideload; that script greps this constant,
    // so the two move together. ADR-0032, ADR-0034
    const APP_VERSION = "0.29";

    // Defaults are where a wearer starts looking, never answers. One person's
    // measured resonance frequency dressed as a default would be a wrong number
    // wearing a right number's clothes. ADR-0022
    const DEFAULT_EVERY_MILLIS = 5000;
    const DEFAULT_VIBE_STRENGTH = 20;
    const DEFAULT_VIBE_DURATION = 100;

    // The interval in MILLISECONDS, and the pace in hundredths of a breath per
    // minute: ONE range in two units. Read the two together -- neither is free
    // to move on its own, and their coherence is asserted rather than described
    // here. ADR-0018, ADR-0019, ADR-0022
    const MIN_EVERY_MILLIS = 3000;
    const MAX_EVERY_MILLIS = 15000;
    const MIN_PACE_HUNDREDTHS = 200;
    const MAX_PACE_HUNDREDTHS = 1000;

    // The precision the measuring tools report. ADR-0020
    const PACE_STEP = 1;

    // The floor is the weakest cue the API can express, not silence. ADR-0023
    const MIN_VIBE_STRENGTH = 1;
    const MAX_VIBE_STRENGTH = 100;

    // Below perception at one end, short of a buzz at the other. ADR-0024
    const MIN_VIBE_DURATION = 10;
    const MAX_VIBE_DURATION = 250;

    // EVERY's step SNAPS rather than adds. POWER has no single step -- its
    // two-zone ladder lives in CandleMath. ADR-0021, ADR-0023
    const EVERY_STEP_MILLIS = 50;
    const DURATION_STEP = 10;

    // **Storage keys are on-disk API.** Both legacy interval keys below are
    // still read and migrated. ADR-0025
    const EVERY_STORAGE_KEY = "everyMillis";
    const STRENGTH_STORAGE_KEY = "vibrationStrength";
    const DURATION_STORAGE_KEY = "vibrationDuration";

    // Hundredths of a second. Its whole range converts, so no plausibility
    // window. ADR-0017
    const LEGACY_EVERY_HUNDREDTHS_KEY = "everyHundredths";
    const LEGACY_EVERY_MIN = 5;
    const LEGACY_EVERY_MAX = 1500;

    // Hundredths of a bpm, and the band that build could actually write.
    // Anything outside it is not a pace and is left alone. ADR-0016
    const LEGACY_PACE_STORAGE_KEY = "paceHundredths";
    const LEGACY_PACE_MIN = 450;
    const LEGACY_PACE_MAX = 700;

    private var _timer as Timer.Timer? = null;
    private var _everyMillis as Number = DEFAULT_EVERY_MILLIS;
    private var _vibeStrength as Number = DEFAULT_VIBE_STRENGTH;
    private var _vibeDuration as Number = DEFAULT_VIBE_DURATION;

    // Rebuilt only when strength or duration changes. ADR-0027
    private var _vibeProfiles as Array<Attention.VibeProfile>? = null;

    // Timer.Timer does not report its own period. See getTimerPeriodMillis.
    private var _timerPeriodMillis as Number = 0;

    // Gates the cue timer's redraw to once a minute. ADR-0006
    private var _lastRedrawMinute as Number = -1;

    // Long enough to read four words, short enough that a sleeve brushing the
    // glass costs a glance rather than a screen. ADR-0009
    const EXIT_HINT_MILLIS = 2000;

    // The app's THIRD and last timer -- the device allows three. ADR-0006
    private var _hintTimer as Timer.Timer? = null;
    private var _showExitHint as Boolean = false;

    function initialize() {
        AppBase.initialize();
        loadSettings();
    }

    function onStart(state as Dictionary?) as Void {
        startTimer();
    }

    // Buzz, and carry the clock: the cue is the only thing already ticking, so
    // it doubles as the clock's refresh rather than a second timer beside it.
    // ADR-0006
    //
    // Every cue is identical and carries no phase -- read ADR-0002 before
    // "improving" that. No mute branch either: the weakest setting still asks
    // the hardware for a cue, and whether one arrives is the hardware's
    // answer to give. ADR-0023
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

    // Public so a test can read the profile the wrist will feel rather than the
    // two numbers it was built from. ADR-0027
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
    // the foreground, so redraw rather than wait for the next cue. ADR-0006
    function onActive(state as Dictionary?) as Void {
        WatchUi.requestUpdate();
    }

    // --- the exit hint --------------------------------------------------------
    //
    // The state lives here rather than on the delegate because the view draws
    // it and the view already reads the app; parking it on the delegate would
    // mean the two screens each holding a piece of one fact. ADR-0009

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

    // The stored value IS the timer period. ADR-0018
    function startTimer() as Void {
        stopTimer();
        var period = _everyMillis;
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

    // Timer.Timer does not report its own period, so without this there is no
    // way to assert the one thing a pace change must do: restart the cue at the
    // new cadence. Only startTimer writes it. ADR-0027
    function getTimerPeriodMillis() as Number {
        return _timerPeriodMillis;
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [
            new candleView(Rows.SCREEN_MAIN),
            new candleDelegate(Rows.SCREEN_MAIN)
        ];
    }

    function getEveryMillis() as Number {
        return _everyMillis;
    }

    function getVibrationStrength() as Number {
        return _vibeStrength;
    }

    function getVibrationDuration() as Number {
        return _vibeDuration;
    }

    // --- what a row shows, and what one tap does to it ------------------------
    //
    // Both keyed by row IDENTITY, never by where it is drawn, so moving a
    // setting to another screen is a one-line edit in Rows. ADR-0028

    function rowValueText(row as Number) as String {
        if (row == Rows.EVERY) {
            return CandleMath.rowValueText(row, _everyMillis);
        }
        if (row == Rows.PACE) {
            return CandleMath.rowValueText(row, CandleMath.everyToPace(_everyMillis));
        }
        if (row == Rows.PULSE) {
            return CandleMath.rowValueText(row, _vibeDuration);
        }
        return CandleMath.rowValueText(row, _vibeStrength);
    }

    // Every arm is deliberately unclamped -- each setter clamps. ADR-0026
    function stepRow(row as Number, increase as Boolean) as Void {
        if (row == Rows.EVERY) {
            // Snapped to the ladder, not added to it. ADR-0021
            setEveryMillis(increase
                ? CandleMath.everyUp(_everyMillis, EVERY_STEP_MILLIS)
                : CandleMath.everyDown(_everyMillis, EVERY_STEP_MILLIS));
        } else if (row == Rows.PACE) {
            // Stepped from the value ON THE GLASS, not from the stored
            // interval, which is what makes "+" then "-" return. And "+" here
            // SHORTENS the interval where "+" on EVERY lengthens it. ADR-0019
            setPaceHundredths(
                CandleMath.everyToPace(_everyMillis) + (increase ? PACE_STEP : -PACE_STEP));
        } else if (row == Rows.PULSE) {
            setVibrationDuration(_vibeDuration + (increase ? DURATION_STEP : -DURATION_STEP));
        } else {
            setVibrationStrength(increase
                ? CandleMath.strengthUp(_vibeStrength)
                : CandleMath.strengthDown(_vibeStrength));
        }
    }

    // The setters clamp rather than reject, and the unchanged guard is what
    // that clamping makes necessary: without it, every tap on "+" at the
    // maximum would rewrite Storage and restart the cue timer to no effect.
    // ADR-0026

    function setEveryMillis(value as Number) as Void {
        var next = CandleMath.clamp(value, MIN_EVERY_MILLIS, MAX_EVERY_MILLIS);
        if (next == _everyMillis) {
            return;
        }

        _everyMillis = next;
        Storage.setValue(EVERY_STORAGE_KEY, next);

        if (_timer != null) {
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    // The only place the two units meet. It clamps in BPM and converts
    // afterwards, and that order is the correctness argument: clamping in
    // interval units would let a pace step land on an interval that is on no
    // bpm rung. No Storage write and no key of its own -- it ends in the
    // interval setter and inherits everything from it. ADR-0019
    function setPaceHundredths(value as Number) as Void {
        setEveryMillis(CandleMath.paceToEvery(
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

    // Public for one reason: a test can only prove the migration by staging
    // Storage and re-running this. ADR-0025
    function loadSettings() as Void {
        migrateStoredInterval();
        _everyMillis = readStoredNumber(
            EVERY_STORAGE_KEY, MIN_EVERY_MILLIS, MAX_EVERY_MILLIS, DEFAULT_EVERY_MILLIS);
        _vibeStrength = readStoredNumber(
            STRENGTH_STORAGE_KEY, MIN_VIBE_STRENGTH, MAX_VIBE_STRENGTH, DEFAULT_VIBE_STRENGTH);
        _vibeDuration = readStoredNumber(
            DURATION_STORAGE_KEY, MIN_VIBE_DURATION, MAX_VIBE_DURATION, DEFAULT_VIBE_DURATION);
    }

    // Newest key first, converting at most once and deleting each legacy key as
    // it is consumed so a conversion cannot run twice. ADR-0025
    private function migrateStoredInterval() as Void {
        var current = Storage.getValue(EVERY_STORAGE_KEY);
        if (current instanceof Number
                && current >= MIN_EVERY_MILLIS && current <= MAX_EVERY_MILLIS) {
            return;
        }

        // Clamped, because the old range reached below today's floor: a wearer
        // parked under it gets the floor rather than the default, which is the
        // nearer of the two to what they had. ADR-0022
        var hundredths = Storage.getValue(LEGACY_EVERY_HUNDREDTHS_KEY);
        if (hundredths instanceof Number
                && hundredths >= LEGACY_EVERY_MIN && hundredths <= LEGACY_EVERY_MAX) {
            Storage.setValue(
                EVERY_STORAGE_KEY,
                CandleMath.clamp(hundredths * 10, MIN_EVERY_MILLIS, MAX_EVERY_MILLIS));
            Storage.deleteValue(LEGACY_EVERY_HUNDREDTHS_KEY);
            Storage.deleteValue(LEGACY_PACE_STORAGE_KEY);
            return;
        }

        var legacy = Storage.getValue(LEGACY_PACE_STORAGE_KEY);
        if (legacy instanceof Number
                && legacy >= LEGACY_PACE_MIN && legacy <= LEGACY_PACE_MAX) {
            Storage.setValue(EVERY_STORAGE_KEY, CandleMath.paceToEvery(legacy));
            Storage.deleteValue(LEGACY_PACE_STORAGE_KEY);
        }
    }

    // Storage.getValue returns a wide poly type, so a stored value is checked
    // for being a Number AND for being in range before it is trusted. ADR-0025
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
