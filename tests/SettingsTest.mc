import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

// Settings behaviour that can only be observed through the real setters -- or,
// for the migration, through Storage itself.
//
// The clamping arithmetic is tested purely in CandleMathTest; it does not belong
// here, because a test that writes to Storage can strand a value there. The
// four tests in this file that do write (the profile tracker, the range walk,
// the pace ladder and the migration) all restore from a `finally` so a failed
// assertion cannot leave the simulator holding the value it died on.

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
    var savedEvery = app.getEveryMillis();
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
            app.getTimerPeriodMillis(), app.getEveryMillis(),
            "the timer did not start at the current interval");

        app.setEveryMillis(6000);
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), 6000,
            "an interval change did not restart the cue timer -- the cadence would not change");
        app.setEveryMillis(4500);
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), 4500,
            "the cue timer kept the previous interval");
        logger.debug(
            "cue timer follows the interval: 6000 ms then " +
            app.getTimerPeriodMillis() + " ms");

        // A stopped timer reports no period, so a non-zero reading above cannot
        // be a leftover from an earlier start.
        app.stopTimer();
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), 0, "a stopped timer still reports a period");
    } finally {
        app.setEveryMillis(savedEvery);
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
        app.MIN_EVERY_MILLIS < app.MAX_EVERY_MILLIS, "the interval range is inverted");
    Test.assertMessage(
        app.MIN_VIBE_STRENGTH < app.MAX_VIBE_STRENGTH, "the strength range is inverted");
    Test.assertMessage(
        app.MIN_VIBE_DURATION < app.MAX_VIBE_DURATION, "the length range is inverted");

    Test.assertMessage(app.EVERY_STEP_MILLIS > 0, "the interval step must advance");
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

    // The interval range is pinned to its reason, and the reason CHANGED when
    // the PACE row arrived. The floor used to be the platform's 50 ms Timer
    // minimum -- inherited, never chosen. It is now the exact reciprocal of the
    // pace ceiling, and that is the property the whole two-row arrangement
    // rests on: every interval has a pace and every pace has an interval, so
    // neither row can hold a value the other cannot show.
    //
    // Pin the RELATIONSHIP, not the constants, so the ranges stay free to be
    // re-argued as long as they are re-argued together.
    Test.assertEqualMessage(
        app.MIN_EVERY_MILLIS, CandleMath.paceToEvery(app.MAX_PACE_HUNDREDTHS),
        "the interval floor must be exactly the fastest pace's own interval");
    Test.assertEqualMessage(
        app.MAX_EVERY_MILLIS, CandleMath.paceToEvery(app.MIN_PACE_HUNDREDTHS),
        "the interval ceiling must be exactly the slowest pace's own interval");

    // The 50 ms minimum has not gone away, it has stopped being the binding
    // constraint. The floor may never go under it whatever the pace ceiling is
    // argued to.
    Test.assertMessage(
        app.MIN_EVERY_MILLIS >= 50,
        "the interval floor is under the platform's 50 ms Timer minimum");
    Test.assertEqualMessage(
        app.MAX_EVERY_MILLIS, 15000,
        "the interval ceiling is 15 s between cues");

    // A 0.1 bpm tap only moves the stored interval while 3000/b^2 >= 1, i.e.
    // below about 17.3 bpm. Past that, adjacent rungs round to the same
    // hundredth and the "+" control silently does nothing -- 25.0 and 25.1 bpm
    // both store 120. This is that bound, asserted where it actually bites
    // rather than as a magic number: the top two rungs must differ.
    Test.assertNotEqualMessage(
        CandleMath.paceToEvery(app.MAX_PACE_HUNDREDTHS),
        CandleMath.paceToEvery(app.MAX_PACE_HUNDREDTHS - app.PACE_STEP),
        "the pace ceiling is high enough that its top tap changes nothing");

    // A default outside its own range would be silently replaced on first run.
    Test.assertEqualMessage(
        CandleMath.clamp(app.DEFAULT_EVERY_MILLIS, app.MIN_EVERY_MILLIS, app.MAX_EVERY_MILLIS),
        app.DEFAULT_EVERY_MILLIS, "the default interval is outside the interval range");
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
        (app.MAX_EVERY_MILLIS - app.MIN_EVERY_MILLIS) % app.EVERY_STEP_MILLIS, 0,
        "the interval step does not divide the interval range");
    Test.assertEqualMessage(
        (app.MAX_PACE_HUNDREDTHS - app.MIN_PACE_HUNDREDTHS) % app.PACE_STEP, 0,
        "the pace step does not divide the pace range");
    Test.assertEqualMessage(
        (app.MAX_VIBE_DURATION - app.MIN_VIBE_DURATION) % app.DURATION_STEP, 0,
        "the length step does not divide the length range");

    // ...and each default sits on its own ladder, so a fresh install starts on a
    // value the taps can come back to. A default one step beside the ladder is
    // how the strength scale ran on odd percents for as long as it did.
    Test.assertEqualMessage(
        (app.DEFAULT_EVERY_MILLIS - app.MIN_EVERY_MILLIS) % app.EVERY_STEP_MILLIS, 0,
        "the default interval is off the interval ladder");
    // ...and off the PACE row's ladder too, since the default is the one value
    // both rows are guaranteed to show a fresh install.
    Test.assertEqualMessage(
        (CandleMath.everyToPace(app.DEFAULT_EVERY_MILLIS) - app.MIN_PACE_HUNDREDTHS)
            % app.PACE_STEP, 0,
        "the default interval reads as a pace that is off the pace ladder");
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
    var savedEvery = app.getEveryMillis();
    var savedStrength = app.getVibrationStrength();
    var savedDuration = app.getVibrationDuration();

    try {
        app.setEveryMillis(app.MIN_EVERY_MILLIS);
        var taps = 0;
        while (app.getEveryMillis() < app.MAX_EVERY_MILLIS && taps < 1000) {
            app.setEveryMillis(app.getEveryMillis() + app.EVERY_STEP_MILLIS);
            Test.assertMessage(
                app.getEveryMillis() <= app.MAX_EVERY_MILLIS,
                "stepping up overshot the interval ceiling: " + app.getEveryMillis()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getEveryMillis(), app.MAX_EVERY_MILLIS,
            "stepping up must reach the interval ceiling"
        );
        logger.debug("interval: " + taps + " taps from floor to ceiling");

        // A migrated measurement lands off the 0.05 ladder (5.71 bpm -> 5.25 s
        // is on it, but 5.70 bpm -> 5.26 s is not). One tap down from just off
        // the floor must land ON the floor, and a single out-of-range request
        // must clamp in one write -- both are the setter's clamp at work.
        app.setEveryMillis(app.MIN_EVERY_MILLIS + 3);
        app.setEveryMillis(app.getEveryMillis() - app.EVERY_STEP_MILLIS);
        Test.assertEqualMessage(
            app.getEveryMillis(), app.MIN_EVERY_MILLIS,
            "stepping down off the ladder must land on the floor, not below or beside it"
        );
        app.setEveryMillis(app.MAX_EVERY_MILLIS + 7);
        Test.assertEqualMessage(
            app.getEveryMillis(), app.MAX_EVERY_MILLIS,
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
        app.setEveryMillis(savedEvery);
        app.setVibrationStrength(savedStrength);
        app.setVibrationDuration(savedDuration);
    }

    Test.assertEqualMessage(app.getEveryMillis(), savedEvery, "the interval was not restored");
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
    var savedEvery = app.getEveryMillis();

    try {
        // A plausible legacy pace, no new value yet: converted, persisted
        // under the new key, and the legacy key removed so it cannot run twice.
        Storage.deleteValue(app.EVERY_STORAGE_KEY);
        Storage.setValue(app.LEGACY_PACE_STORAGE_KEY, 571);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryMillis(), 5254, "5.71 bpm should migrate to a 5.254 s interval");
        Test.assertEqualMessage(
            Storage.getValue(app.EVERY_STORAGE_KEY) as Number, 5254,
            "the migrated interval must be persisted, not just held in memory");
        Test.assertMessage(
            Storage.getValue(app.LEGACY_PACE_STORAGE_KEY) == null,
            "the legacy key must be deleted so the conversion cannot repeat");

        // Both keys present: the new value wins and the legacy key is left
        // exactly as it lies -- it is dead data, not an input.
        Storage.setValue(app.EVERY_STORAGE_KEY, 7000);
        Storage.setValue(app.LEGACY_PACE_STORAGE_KEY, 600);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryMillis(), 7000, "a valid new value must never be overridden");
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
            app.getEveryMillis(), app.DEFAULT_EVERY_MILLIS,
            "an implausible legacy value must fall back to the default");
        Storage.deleteValue(app.LEGACY_PACE_STORAGE_KEY);

        // Nothing stored at all: a fresh install starts at the default.
        Storage.deleteValue(app.EVERY_STORAGE_KEY);
        app.loadSettings();
        Test.assertEqualMessage(
            app.getEveryMillis(), app.DEFAULT_EVERY_MILLIS,
            "a fresh install must start at the default interval");
    } finally {
        // The setter early-returns on an unchanged value without writing, so
        // restore Storage directly and reload rather than trusting it.
        Storage.setValue(app.EVERY_STORAGE_KEY, savedEvery);
        app.loadSettings();
    }

    Test.assertEqualMessage(
        app.getEveryMillis(), savedEvery, "the interval was not restored");
    return true;
}

// PACE and EVERY are ONE setting in two units, and this walks every rung of the
// bpm ladder to prove the pair holds together.
//
// Three properties, and a reciprocal will quietly break all three if nobody
// looks. For every pace the row can show:
//
//   * it maps to an interval INSIDE the interval range, so no pace can ask for
//     something the interval setter would clamp away underneath it;
//   * it maps to a DISTINCT interval, so no two rungs collide -- a collision is
//     a tap that changes the number on the glass and nothing else;
//   * it survives the round trip back through everyToPace, so a "+" followed by
//     a "-" lands exactly where it started.
//
// Then the other direction: every interval the EVERY row can reach must read as
// a pace the PACE row can show, whether or not it happens to sit on a rung.
// That is the half that makes the two rows genuinely two views rather than two
// settings that mostly agree.
//
// All 81 rungs and all 1201 intervals, not a sample -- the failures a reciprocal
// produces are not spread evenly, they cluster where the curve is steep, and a
// sampled walk is exactly how you miss them. It is pure arithmetic and touches
// no Storage: paceToEvery and everyToPace are the whole of the coupling.
(:test)
function settingsPaceAndEveryAreOneSettingTwoViews(logger as Test.Logger) as Boolean {
    var app = getApp();
    var previous = -1;
    var rungs = 0;

    for (var p = app.MIN_PACE_HUNDREDTHS; p <= app.MAX_PACE_HUNDREDTHS; p += app.PACE_STEP) {
        var every = CandleMath.paceToEvery(p);

        Test.assertMessage(
            every >= app.MIN_EVERY_MILLIS && every <= app.MAX_EVERY_MILLIS,
            "pace " + p + " maps to interval " + every + ", outside " +
                app.MIN_EVERY_MILLIS + ".." + app.MAX_EVERY_MILLIS);

        Test.assertMessage(
            every != previous,
            "pace " + p + " and the rung below it both store interval " + every +
                " -- one of the two taps between them does nothing at all");
        previous = every;

        Test.assertEqualMessage(
            CandleMath.everyToPace(every), p,
            "pace " + p + " stores as interval " + every + " and reads back as " +
                CandleMath.everyToPace(every) + ", so + then - would not return");
        rungs += 1;
    }
    logger.debug("walked " + rungs + " pace rungs: all distinct, all reversible");

    // The endpoints meet exactly, with nothing rounded at either end.
    Test.assertEqualMessage(
        CandleMath.paceToEvery(app.MAX_PACE_HUNDREDTHS), app.MIN_EVERY_MILLIS,
        "the fastest pace must be exactly the shortest interval");
    Test.assertEqualMessage(
        CandleMath.paceToEvery(app.MIN_PACE_HUNDREDTHS), app.MAX_EVERY_MILLIS,
        "the slowest pace must be exactly the longest interval");

    var intervals = 0;
    for (var e = app.MIN_EVERY_MILLIS; e <= app.MAX_EVERY_MILLIS; e += 1) {
        var pace = CandleMath.everyToPace(e);
        Test.assertMessage(
            pace >= app.MIN_PACE_HUNDREDTHS && pace <= app.MAX_PACE_HUNDREDTHS,
            "interval " + e + " reads as pace " + pace + ", which is outside " +
                app.MIN_PACE_HUNDREDTHS + ".." + app.MAX_PACE_HUNDREDTHS +
                " -- the PACE row would show a value its controls cannot leave");
        intervals += 1;
    }
    logger.debug("checked " + intervals + " intervals: every one has a pace on the row");
    return true;
}

// The PACE row's taps, through the real setter, exactly as a thumb drives them.
//
// settingsPaceAndEveryAreOneSettingTwoViews proves the arithmetic; this proves
// the wiring on top of it -- that stepRow reads the value off the glass rather
// than out of Storage, that a step lands on the adjacent rung, and that both
// ends clamp instead of running past.
//
// Storage is written here, so it restores from a finally like the other three.
(:test)
function settingsPaceStepsWalkTheirOwnLadder(logger as Test.Logger) as Boolean {
    var app = getApp();
    var savedEvery = app.getEveryMillis();

    try {
        // From the default, one tap each way must land on the neighbouring rung
        // and come straight back. This is the property that fails if stepRow
        // ever steps from the stored interval instead of the displayed pace.
        app.setEveryMillis(app.DEFAULT_EVERY_MILLIS);
        var start = CandleMath.everyToPace(app.getEveryMillis());

        app.stepRow(Rows.PACE, true);
        Test.assertEqualMessage(
            CandleMath.everyToPace(app.getEveryMillis()), start + app.PACE_STEP,
            "one PACE tap up must land on the next rung");
        app.stepRow(Rows.PACE, false);
        Test.assertEqualMessage(
            CandleMath.everyToPace(app.getEveryMillis()), start,
            "PACE up then down must return to the rung it started on");

        // "+" on PACE shortens the interval, where "+" on EVERY lengthens it.
        // Reciprocal units cannot agree on which way is up, and a bpm row whose
        // "+" lowered the bpm would be the wrong fix for that.
        var before = app.getEveryMillis();
        app.stepRow(Rows.PACE, true);
        Test.assertMessage(
            app.getEveryMillis() < before,
            "a faster pace must be a shorter interval: " + before + " -> " +
                app.getEveryMillis());

        // Both ends clamp. Walking off either end must stop on the endpoint
        // rather than run past it or wrap.
        app.setPaceHundredths(app.MAX_PACE_HUNDREDTHS);
        app.stepRow(Rows.PACE, true);
        Test.assertEqualMessage(
            app.getEveryMillis(), app.MIN_EVERY_MILLIS,
            "stepping up at the pace ceiling must stay on the interval floor");

        app.setPaceHundredths(app.MIN_PACE_HUNDREDTHS);
        app.stepRow(Rows.PACE, false);
        Test.assertEqualMessage(
            app.getEveryMillis(), app.MAX_EVERY_MILLIS,
            "stepping down at the pace floor must stay on the interval ceiling");

        // An interval left BETWEEN two rungs by an EVERY tap -- which is most of
        // them, since the two ladders line up only at 7.75 bpm. The pace tap
        // must still land on a rung, not on the same off-ladder offset.
        app.setEveryMillis(CandleMath.paceToEvery(573));
        app.stepRow(Rows.PACE, true);
        Test.assertEqualMessage(
            CandleMath.everyToPace(app.getEveryMillis()) % app.PACE_STEP, 0,
            "a PACE tap from an off-rung interval must land ON a rung");
    } finally {
        app.setEveryMillis(savedEvery);
    }

    Test.assertEqualMessage(
        app.getEveryMillis(), savedEvery, "the interval was not restored");
    return true;
}
