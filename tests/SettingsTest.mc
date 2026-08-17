import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

// Settings behaviour that can only be observed through the real setters -- or,
// for the migration, through Storage itself.
//
// The clamping arithmetic is tested purely in CandleMathTest; it does not belong
// here, because a test that writes to Storage can strand a value there. The
// three tests in this file that do write (the profile tracker, the range walk,
// and the migration) all restore from a `finally` so a failed assertion cannot
// leave the simulator holding the value it died on.

// The cue the wrist will actually feel, read through the same accessor
// timerCallback hands to Attention.vibrate.
//
// Every other test here checks the numbers a setting holds. This one checks the
// two things that stand between those numbers and the motor, neither of which
// any other test can see:
//
//   * The VibeProfile is cached so it is not reallocated ~11 times a minute, and
//     both vibe setters invalidate that cache. If one ever stopped, the screen
//     would show the new value while the wrist kept feeling the old one.
//   * The cue timer is restarted on a pace change. Timer.Timer does not report
//     its period, so candleApp records what it started, and only startTimer
//     writes it.
//
// Attention.vibrate does nothing observable in the simulator, so this is as far
// as verification goes from here: it proves the right profile reaches the call,
// not that the motor obeys it.
(:test)
function settingsVibeProfileTracksSettingChanges(logger as Test.Logger) as Boolean {
    var app = getApp();
    var savedEvery = app.getEveryHundredths();
    var savedStrength = app.getVibrationStrength();
    var savedDuration = app.getVibrationDuration();

    try {
        app.setVibrationStrength(40);
        app.setVibrationDuration(120);

        var profiles = app.vibeProfiles();
        Test.assertEqualMessage(
            profiles.size(), 1, "one cue per callback, not " + profiles.size());
        Test.assertEqualMessage(
            profiles[0].dutyCycle, 40, "the profile did not start at the set strength");
        Test.assertEqualMessage(
            profiles[0].length, 120, "the profile did not start at the set length");

        // Strength moves; length must not.
        app.setVibrationStrength(80);
        profiles = app.vibeProfiles();
        Test.assertEqualMessage(
            profiles[0].dutyCycle, 80,
            "a strength change never reached the cue -- the profile cache was not invalidated");
        Test.assertEqualMessage(
            profiles[0].length, 120, "a strength change disturbed the length");

        // Length moves; strength must not.
        app.setVibrationDuration(200);
        profiles = app.vibeProfiles();
        Test.assertEqualMessage(
            profiles[0].length, 200,
            "a length change never reached the cue -- the profile cache was not invalidated");
        Test.assertEqualMessage(
            profiles[0].dutyCycle, 80, "a length change disturbed the strength");

        // Walking to a bound and back, the way a thumb does, must still land on
        // the profile: the setters early-return when a value is unchanged, and
        // that guard must not swallow a real change.
        app.setVibrationStrength(app.MAX_VIBE_STRENGTH);
        app.setVibrationStrength(app.MAX_VIBE_STRENGTH);
        Test.assertEqualMessage(
            app.vibeProfiles()[0].dutyCycle, app.MAX_VIBE_STRENGTH,
            "the cue did not follow the strength to its ceiling");
        app.setVibrationStrength(app.MIN_VIBE_STRENGTH);
        Test.assertEqualMessage(
            app.vibeProfiles()[0].dutyCycle, app.MIN_VIBE_STRENGTH,
            "the cue did not follow the strength back to its floor");

        // The cue timer must follow the interval while it is running.
        app.startTimer();
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), CandleMath.intervalMillis(app.getEveryHundredths()),
            "the timer did not start at the current interval");

        app.setEveryHundredths(600);
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), CandleMath.intervalMillis(600),
            "an interval change did not restart the cue timer -- the cadence would not change");
        app.setEveryHundredths(450);
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), CandleMath.intervalMillis(450),
            "the cue timer kept the previous interval");
        logger.debug(
            "600 -> " + CandleMath.intervalMillis(600) + " ms, 450 -> " +
            CandleMath.intervalMillis(450) + " ms");

        // A stopped timer reports no period, so a non-zero reading above cannot
        // be a leftover from an earlier start.
        app.stopTimer();
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), 0, "a stopped timer still reports a period");
    } finally {
        app.setEveryHundredths(savedEvery);
        app.setVibrationStrength(savedStrength);
        app.setVibrationDuration(savedDuration);
        app.startTimer();
    }
    return true;
}

// Range and step declarations must be coherent before any of them is walked.
// Reads constants only -- nothing here writes.
(:test)
function settingsRangesAndStepsAreCoherent(logger as Test.Logger) as Boolean {
    var app = getApp();

    Test.assertMessage(
        app.MIN_EVERY_HUNDREDTHS < app.MAX_EVERY_HUNDREDTHS, "the interval range is inverted");
    Test.assertMessage(
        app.MIN_VIBE_STRENGTH < app.MAX_VIBE_STRENGTH, "the strength range is inverted");
    Test.assertMessage(
        app.MIN_VIBE_DURATION < app.MAX_VIBE_DURATION, "the length range is inverted");

    Test.assertMessage(app.EVERY_STEP > 0, "the interval step must advance");
    Test.assertMessage(app.DURATION_STEP > 0, "the length step must advance");

    // POWER walks a two-zone ladder instead of a single step. What must hold:
    // the ceiling and the default sit on coarse rungs, the fine zone runs into
    // the floor by single percents, and the zones meet at the fine limit with
    // no gap in either direction.
    Test.assertEqualMessage(
        app.MAX_VIBE_STRENGTH % CandleMath.STRENGTH_COARSE_STEP, 0,
        "the strength ceiling is off the coarse ladder");
    Test.assertEqualMessage(
        app.DEFAULT_VIBE_STRENGTH % CandleMath.STRENGTH_COARSE_STEP, 0,
        "the default strength is off the coarse ladder");
    Test.assertEqualMessage(
        CandleMath.strengthDown(app.MIN_VIBE_STRENGTH + 1), app.MIN_VIBE_STRENGTH,
        "the fine zone must reach the floor by single percents");
    Test.assertEqualMessage(
        CandleMath.strengthUp(CandleMath.STRENGTH_FINE_LIMIT),
        2 * CandleMath.STRENGTH_COARSE_STEP,
        "one tap up from the fine limit must land on the next coarse rung");
    Test.assertEqualMessage(
        CandleMath.strengthDown(2 * CandleMath.STRENGTH_COARSE_STEP),
        CandleMath.STRENGTH_FINE_LIMIT,
        "one tap down from that rung must land back on the fine limit");

    // The floor is pinned to its reason: 0.05 s exists because the platform's
    // documented Timer minimum is 50 ms, and the two must never drift apart.
    // The ceiling is a design choice and is pinned only through the same
    // conversion, so the constant itself stays free to be re-argued.
    Test.assertEqualMessage(
        CandleMath.intervalMillis(app.MIN_EVERY_HUNDREDTHS), 50,
        "the interval floor must be exactly the 50 ms Timer minimum");
    Test.assertEqualMessage(
        CandleMath.intervalMillis(app.MAX_EVERY_HUNDREDTHS), 15000,
        "the interval ceiling is 15 s between cues");

    // A default outside its own range would be silently replaced on first run.
    Test.assertEqualMessage(
        CandleMath.clamp(app.DEFAULT_EVERY_HUNDREDTHS, app.MIN_EVERY_HUNDREDTHS, app.MAX_EVERY_HUNDREDTHS),
        app.DEFAULT_EVERY_HUNDREDTHS, "the default interval is outside the interval range");
    Test.assertEqualMessage(
        CandleMath.clamp(app.DEFAULT_VIBE_STRENGTH, app.MIN_VIBE_STRENGTH, app.MAX_VIBE_STRENGTH),
        app.DEFAULT_VIBE_STRENGTH, "the default strength is outside the strength range");
    Test.assertEqualMessage(
        CandleMath.clamp(app.DEFAULT_VIBE_DURATION, app.MIN_VIBE_DURATION, app.MAX_VIBE_DURATION),
        app.DEFAULT_VIBE_DURATION, "the default length is outside the length range");

    // Every range divides evenly by its own step, so a walk lands exactly on both
    // endpoints instead of stalling one step short of one of them. This replaces
    // a pin on the literal floor value, which duplicated a constant a UI tweak is
    // allowed to move; the ladder is the property that must hold whatever the
    // floor is tuned to.
    Test.assertEqualMessage(
        (app.MAX_EVERY_HUNDREDTHS - app.MIN_EVERY_HUNDREDTHS) % app.EVERY_STEP, 0,
        "the interval step does not divide the interval range");
    Test.assertEqualMessage(
        (app.MAX_VIBE_DURATION - app.MIN_VIBE_DURATION) % app.DURATION_STEP, 0,
        "the length step does not divide the length range");

    // ...and each default sits on its own ladder, so a fresh install starts on a
    // value the taps can come back to. A default one step beside the ladder is
    // how the strength scale ran on odd percents for as long as it did.
    Test.assertEqualMessage(
        (app.DEFAULT_EVERY_HUNDREDTHS - app.MIN_EVERY_HUNDREDTHS) % app.EVERY_STEP, 0,
        "the default interval is off the interval ladder");
    Test.assertEqualMessage(
        (app.DEFAULT_VIBE_DURATION - app.MIN_VIBE_DURATION) % app.DURATION_STEP, 0,
        "the default length is off the length ladder");

    // The strength scale bottoms out at the weakest cue the hardware can be
    // asked for, not at silence. Nothing may quietly reintroduce a mute.
    Test.assertMessage(
        app.MIN_VIBE_STRENGTH > 0,
        "the strength floor must still ask for a cue -- 0% would be no vibration");
    return true;
}

// Walk each range end to end exactly as the tap controls do. Every value must
// stay inside the range, and both endpoints must actually be reached.
//
// This is also the only coverage that the setters really clamp. Every range
// divides evenly by its own step now, so a walk that starts on the ladder never
// needs the clamp at all -- which is why the last leg below starts off it. A
// value stored by an earlier build need not be on the current ladder: strength
// ran 1..100 by 2 until the floor moved to 2, so every value that build wrote is
// odd, and from an odd value the tap that should reach 100% asks for 101.
// Landing on the endpoint is only possible if that request is clamped rather
// than rejected -- rejecting it would leave the "+" control dead one step short
// of the top with nothing on screen to explain why.
(:test)
function settingsStepsWalkEveryRangeEndToEnd(logger as Test.Logger) as Boolean {
    var app = getApp();
    var savedEvery = app.getEveryHundredths();
    var savedStrength = app.getVibrationStrength();
    var savedDuration = app.getVibrationDuration();

    try {
        app.setEveryHundredths(app.MIN_EVERY_HUNDREDTHS);
        var taps = 0;
        while (app.getEveryHundredths() < app.MAX_EVERY_HUNDREDTHS && taps < 1000) {
            app.setEveryHundredths(app.getEveryHundredths() + app.EVERY_STEP);
            Test.assertMessage(
                app.getEveryHundredths() <= app.MAX_EVERY_HUNDREDTHS,
                "stepping up overshot the interval ceiling: " + app.getEveryHundredths()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getEveryHundredths(), app.MAX_EVERY_HUNDREDTHS,
            "stepping up must reach the interval ceiling"
        );
        logger.debug("interval: " + taps + " taps from floor to ceiling");

        // A migrated measurement lands off the 0.05 ladder (5.71 bpm -> 5.25 s
        // is on it, but 5.70 bpm -> 5.26 s is not). One tap down from just off
        // the floor must land ON the floor, and a single out-of-range request
        // must clamp in one write -- both are the setter's clamp at work.
        app.setEveryHundredths(app.MIN_EVERY_HUNDREDTHS + 3);
        app.setEveryHundredths(app.getEveryHundredths() - app.EVERY_STEP);
        Test.assertEqualMessage(
            app.getEveryHundredths(), app.MIN_EVERY_HUNDREDTHS,
            "stepping down off the ladder must land on the floor, not below or beside it"
        );
        app.setEveryHundredths(app.MAX_EVERY_HUNDREDTHS + 7);
        Test.assertEqualMessage(
            app.getEveryHundredths(), app.MAX_EVERY_HUNDREDTHS,
            "an out-of-range interval must clamp to the ceiling in a single write"
        );

        app.setVibrationStrength(app.MIN_VIBE_STRENGTH);
        taps = 0;
        while (app.getVibrationStrength() < app.MAX_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(CandleMath.strengthUp(app.getVibrationStrength()));
            Test.assertMessage(
                app.getVibrationStrength() <= app.MAX_VIBE_STRENGTH,
                "stepping up overshot 100%: " + app.getVibrationStrength()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MAX_VIBE_STRENGTH,
            "walking the ladder up must still reach 100%"
        );
        logger.debug("strength: " + taps + " taps from floor to ceiling");

        taps = 0;
        while (app.getVibrationStrength() > app.MIN_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(CandleMath.strengthDown(app.getVibrationStrength()));
            Test.assertMessage(
                app.getVibrationStrength() >= app.MIN_VIBE_STRENGTH,
                "stepping down undershot the strength floor: " + app.getVibrationStrength()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MIN_VIBE_STRENGTH,
            "walking the ladder down must reach the strength floor"
        );

        // Off the ladder, in both directions -- 14% is what a value written by
        // the 2..100-by-2 build looks like to this one. The ladder functions
        // snap it in the tap's own direction; through the real setters the walk
        // must still land exactly on both endpoints.
        app.setVibrationStrength(14);
        taps = 0;
        while (app.getVibrationStrength() > app.MIN_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(CandleMath.strengthDown(app.getVibrationStrength()));
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MIN_VIBE_STRENGTH,
            "stepping down off the ladder must land on the floor, not below or beside it"
        );

        app.setVibrationStrength(14);
        taps = 0;
        while (app.getVibrationStrength() < app.MAX_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(CandleMath.strengthUp(app.getVibrationStrength()));
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MAX_VIBE_STRENGTH,
            "stepping up off the ladder must still land exactly on 100%"
        );
        logger.debug("strength: " + taps + " taps from an off-ladder 14% to the ceiling");

        app.setVibrationDuration(app.MAX_VIBE_DURATION);
        taps = 0;
        while (app.getVibrationDuration() > app.MIN_VIBE_DURATION && taps < 1000) {
            app.setVibrationDuration(app.getVibrationDuration() - app.DURATION_STEP);
            Test.assertMessage(
                app.getVibrationDuration() >= app.MIN_VIBE_DURATION,
                "stepping down undershot the length floor: " + app.getVibrationDuration()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationDuration(), app.MIN_VIBE_DURATION,
            "stepping down must reach the shortest length"
        );
        logger.debug("length: " + taps + " taps from ceiling to floor");
    } finally {
        app.setEveryHundredths(savedEvery);
        app.setVibrationStrength(savedStrength);
        app.setVibrationDuration(savedDuration);
    }

    Test.assertEqualMessage(app.getEveryHundredths(), savedEvery, "the interval was not restored");
    Test.assertEqualMessage(
        app.getVibrationStrength(), savedStrength, "the strength was not restored");
    Test.assertEqualMessage(
        app.getVibrationDuration(), savedDuration, "the length was not restored");
    return true;
}

// The unit change under the interval setting: the old key held hundredths of a
// breath per minute, the new one holds hundredths of a second between cues.
// Reinterpreting the old number under a new name would corrupt every installed
// watch, so the bridge is: convert once, delete the old key, and never let the
// old key override a value the new model has already written.
//
// This is provable only by staging Storage and re-running loadSettings, which
// is why loadSettings is public and why this is the third test allowed to
// write. The finally block writes the saved value straight back to Storage and
// reloads, so even a failed assertion leaves the app exactly as it found it.
(:test)
function settingsMigratesLegacyPace(logger as Test.Logger) as Boolean {
    var app = getApp();
    var savedEvery = app.getEveryHundredths();

    try {
        // A plausible legacy pace, no new value yet: converted, persisted
        // under the new key, and the legacy key removed so it cannot run twice.
        Storage.deleteValue(app.EVERY_STORAGE_KEY);
        Storage.setValue(app.LEGACY_PACE_STORAGE_KEY, 571);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryHundredths(), 525, "5.71 bpm should migrate to a 5.25 s interval");
        Test.assertEqualMessage(
            Storage.getValue(app.EVERY_STORAGE_KEY) as Number, 525,
            "the migrated interval must be persisted, not just held in memory");
        Test.assertMessage(
            Storage.getValue(app.LEGACY_PACE_STORAGE_KEY) == null,
            "the legacy key must be deleted so the conversion cannot repeat");

        // Both keys present: the new value wins and the legacy key is left
        // exactly as it lies -- it is dead data, not an input.
        Storage.setValue(app.EVERY_STORAGE_KEY, 700);
        Storage.setValue(app.LEGACY_PACE_STORAGE_KEY, 600);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryHundredths(), 700, "a valid new value must never be overridden");
        Test.assertEqualMessage(
            Storage.getValue(app.LEGACY_PACE_STORAGE_KEY) as Number, 600,
            "a legacy value beside a valid new one must be left untouched");
        Storage.deleteValue(app.LEGACY_PACE_STORAGE_KEY);

        // An implausible legacy value is not a pace: fall back to the default
        // and leave the junk where it lies rather than converting garbage.
        Storage.deleteValue(app.EVERY_STORAGE_KEY);
        Storage.setValue(app.LEGACY_PACE_STORAGE_KEY, 9999);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryHundredths(), app.DEFAULT_EVERY_HUNDREDTHS,
            "an implausible legacy value must fall back to the default");
        Storage.deleteValue(app.LEGACY_PACE_STORAGE_KEY);

        // Nothing stored at all: a fresh install starts at the default.
        Storage.deleteValue(app.EVERY_STORAGE_KEY);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryHundredths(), app.DEFAULT_EVERY_HUNDREDTHS,
            "a fresh install must start at the default interval");
    } finally {
        // The setter early-returns on an unchanged value without writing, so
        // restore Storage directly and reload rather than trusting it.
        Storage.setValue(app.EVERY_STORAGE_KEY, savedEvery);
        app.loadSettings();
    }

    Test.assertEqualMessage(
        app.getEveryHundredths(), savedEvery, "the interval was not restored");
    return true;
}
