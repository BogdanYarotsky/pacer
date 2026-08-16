import Toybox.Lang;
import Toybox.Test;

// Settings behaviour that can only be observed through the real setters.
//
// The clamping arithmetic itself is tested purely in PacerMathTest -- it does
// not belong here, because every test in this file writes through to Storage and
// a test that writes to Storage can strand a value there. The one below is
// therefore the only one that does, and it restores from a `finally` so a failed
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
//     its period, so pacerApp records what it started, and only startTimer
//     writes it.
//
// Attention.vibrate does nothing observable in the simulator, so this is as far
// as verification goes from here: it proves the right profile reaches the call,
// not that the motor obeys it.
(:test)
function settingsVibeProfileTracksSettingChanges(logger as Test.Logger) as Boolean {
    var app = getApp();
    var savedPace = app.getPaceHundredths();
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

        // The cue timer must follow the pace while it is running.
        app.startTimer();
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), PacerMath.intervalMillis(app.getPaceHundredths()),
            "the timer did not start at the current pace");

        app.setPaceHundredths(600);
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), PacerMath.intervalMillis(600),
            "a pace change did not restart the cue timer -- the cadence would not change");
        app.setPaceHundredths(450);
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), PacerMath.intervalMillis(450),
            "the cue timer kept the previous pace");
        logger.debug(
            "600 -> " + PacerMath.intervalMillis(600) + " ms, 450 -> " +
            PacerMath.intervalMillis(450) + " ms");

        // A stopped timer reports no period, so a non-zero reading above cannot
        // be a leftover from an earlier start.
        app.stopTimer();
        Test.assertEqualMessage(
            app.getTimerPeriodMillis(), 0, "a stopped timer still reports a period");
    } finally {
        app.setPaceHundredths(savedPace);
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
        app.MIN_PACE_HUNDREDTHS < app.MAX_PACE_HUNDREDTHS, "the pace range is inverted");
    Test.assertMessage(
        app.MIN_VIBE_STRENGTH < app.MAX_VIBE_STRENGTH, "the strength range is inverted");
    Test.assertMessage(
        app.MIN_VIBE_DURATION < app.MAX_VIBE_DURATION, "the length range is inverted");

    Test.assertMessage(app.PACE_STEP > 0, "the pace step must advance");
    Test.assertMessage(app.STRENGTH_STEP > 0, "the strength step must advance");
    Test.assertMessage(app.DURATION_STEP > 0, "the length step must advance");

    // A default outside its own range would be silently replaced on first run.
    Test.assertEqualMessage(
        PacerMath.clamp(app.DEFAULT_PACE_HUNDREDTHS, app.MIN_PACE_HUNDREDTHS, app.MAX_PACE_HUNDREDTHS),
        app.DEFAULT_PACE_HUNDREDTHS, "the default pace is outside the pace range");
    Test.assertEqualMessage(
        PacerMath.clamp(app.DEFAULT_VIBE_STRENGTH, app.MIN_VIBE_STRENGTH, app.MAX_VIBE_STRENGTH),
        app.DEFAULT_VIBE_STRENGTH, "the default strength is outside the strength range");
    Test.assertEqualMessage(
        PacerMath.clamp(app.DEFAULT_VIBE_DURATION, app.MIN_VIBE_DURATION, app.MAX_VIBE_DURATION),
        app.DEFAULT_VIBE_DURATION, "the default length is outside the length range");

    // Every range divides evenly by its own step, so a walk lands exactly on both
    // endpoints instead of stalling one step short of one of them. This replaces
    // a pin on the literal floor value, which duplicated a constant a UI tweak is
    // allowed to move; the ladder is the property that must hold whatever the
    // floor is tuned to.
    Test.assertEqualMessage(
        (app.MAX_PACE_HUNDREDTHS - app.MIN_PACE_HUNDREDTHS) % app.PACE_STEP, 0,
        "the pace step does not divide the pace range");
    Test.assertEqualMessage(
        (app.MAX_VIBE_STRENGTH - app.MIN_VIBE_STRENGTH) % app.STRENGTH_STEP, 0,
        "the strength step does not divide the strength range");
    Test.assertEqualMessage(
        (app.MAX_VIBE_DURATION - app.MIN_VIBE_DURATION) % app.DURATION_STEP, 0,
        "the length step does not divide the length range");

    // ...and each default sits on its own ladder, so a fresh install starts on a
    // value the taps can come back to. A default one step beside the ladder is
    // how the strength scale ran on odd percents for as long as it did.
    Test.assertEqualMessage(
        (app.DEFAULT_PACE_HUNDREDTHS - app.MIN_PACE_HUNDREDTHS) % app.PACE_STEP, 0,
        "the default pace is off the pace ladder");
    Test.assertEqualMessage(
        (app.DEFAULT_VIBE_STRENGTH - app.MIN_VIBE_STRENGTH) % app.STRENGTH_STEP, 0,
        "the default strength is off the strength ladder");
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
    var savedPace = app.getPaceHundredths();
    var savedStrength = app.getVibrationStrength();
    var savedDuration = app.getVibrationDuration();

    try {
        app.setPaceHundredths(app.MIN_PACE_HUNDREDTHS);
        var taps = 0;
        while (app.getPaceHundredths() < app.MAX_PACE_HUNDREDTHS && taps < 1000) {
            app.setPaceHundredths(app.getPaceHundredths() + app.PACE_STEP);
            Test.assertMessage(
                app.getPaceHundredths() <= app.MAX_PACE_HUNDREDTHS,
                "stepping up overshot the pace maximum: " + app.getPaceHundredths()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getPaceHundredths(), app.MAX_PACE_HUNDREDTHS,
            "stepping up must reach the maximum pace"
        );
        logger.debug("pace: " + taps + " taps from floor to ceiling");

        app.setVibrationStrength(app.MIN_VIBE_STRENGTH);
        taps = 0;
        while (app.getVibrationStrength() < app.MAX_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(app.getVibrationStrength() + app.STRENGTH_STEP);
            Test.assertMessage(
                app.getVibrationStrength() <= app.MAX_VIBE_STRENGTH,
                "stepping up overshot 100%: " + app.getVibrationStrength()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MAX_VIBE_STRENGTH,
            "stepping up by " + app.STRENGTH_STEP + " must still reach 100%"
        );
        logger.debug("strength: " + taps + " taps from floor to ceiling");

        taps = 0;
        while (app.getVibrationStrength() > app.MIN_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(app.getVibrationStrength() - app.STRENGTH_STEP);
            Test.assertMessage(
                app.getVibrationStrength() >= app.MIN_VIBE_STRENGTH,
                "stepping down undershot the strength floor: " + app.getVibrationStrength()
            );
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MIN_VIBE_STRENGTH,
            "stepping down must reach the strength floor"
        );

        // Off the ladder, in both directions. MIN + 1 is what a value written by
        // the 1..100-by-2 build looks like to this one: the step will never hit
        // an endpoint squarely from there, so only the clamp can land it.
        app.setVibrationStrength(app.MIN_VIBE_STRENGTH + 1);
        taps = 0;
        while (app.getVibrationStrength() > app.MIN_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(app.getVibrationStrength() - app.STRENGTH_STEP);
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MIN_VIBE_STRENGTH,
            "stepping down off the ladder must land on the floor, not below or beside it"
        );

        app.setVibrationStrength(app.MIN_VIBE_STRENGTH + 1);
        taps = 0;
        while (app.getVibrationStrength() < app.MAX_VIBE_STRENGTH && taps < 1000) {
            app.setVibrationStrength(app.getVibrationStrength() + app.STRENGTH_STEP);
            taps += 1;
        }
        Test.assertEqualMessage(
            app.getVibrationStrength(), app.MAX_VIBE_STRENGTH,
            "stepping up off the ladder must still land exactly on 100%"
        );
        logger.debug("strength: " + taps + " taps from one off the floor to the ceiling");

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
        app.setPaceHundredths(savedPace);
        app.setVibrationStrength(savedStrength);
        app.setVibrationDuration(savedDuration);
    }

    Test.assertEqualMessage(app.getPaceHundredths(), savedPace, "the pace was not restored");
    Test.assertEqualMessage(
        app.getVibrationStrength(), savedStrength, "the strength was not restored");
    Test.assertEqualMessage(
        app.getVibrationDuration(), savedDuration, "the length was not restored");
    return true;
}
