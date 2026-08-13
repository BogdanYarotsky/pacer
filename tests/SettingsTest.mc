import Toybox.Lang;
import Toybox.Test;

// The setters clamp to the supported range instead of rejecting an out-of-range
// value, and these tests exist because the strength row now depends on it:
// STRENGTH_STEP is 2 over a 1..100 range, which does not divide evenly. Stepping
// up lands on 99, and the next tap asks for 101. Rejecting that would leave 100%
// permanently unreachable with the "+" control simply going dead one step short
// of the top and nothing on screen to explain why.
//
// These tests write through to Storage, which is the behaviour under test, so
// each one restores the value it found.

(:test)
function settingsPaceClampsToBothEnds(logger as Test.Logger) as Boolean {
    var app = getApp();
    var original = app.getPaceHundredths();

    app.setPaceHundredths(app.MAX_PACE_HUNDREDTHS + 40);
    Test.assertEqualMessage(
        app.getPaceHundredths(), app.MAX_PACE_HUNDREDTHS,
        "a pace above the range should clamp to the maximum"
    );

    app.setPaceHundredths(app.MIN_PACE_HUNDREDTHS - 40);
    Test.assertEqualMessage(
        app.getPaceHundredths(), app.MIN_PACE_HUNDREDTHS,
        "a pace below the range should clamp to the minimum"
    );

    app.setPaceHundredths(original);
    Test.assertEqualMessage(app.getPaceHundredths(), original, "failed to restore the pace");
    return true;
}

(:test)
function settingsStrengthAndDurationClamp(logger as Test.Logger) as Boolean {
    var app = getApp();
    var strength = app.getVibrationStrength();
    var duration = app.getVibrationDuration();

    app.setVibrationStrength(app.MAX_VIBE_STRENGTH + 5);
    Test.assertEqualMessage(
        app.getVibrationStrength(), app.MAX_VIBE_STRENGTH,
        "strength should clamp to 100%"
    );
    app.setVibrationStrength(app.MIN_VIBE_STRENGTH - 5);
    Test.assertEqualMessage(
        app.getVibrationStrength(), app.MIN_VIBE_STRENGTH,
        "strength should clamp to the 1% floor"
    );

    app.setVibrationDuration(app.MAX_VIBE_DURATION + 10);
    Test.assertEqualMessage(
        app.getVibrationDuration(), app.MAX_VIBE_DURATION,
        "duration should clamp to the maximum"
    );
    app.setVibrationDuration(app.MIN_VIBE_DURATION - 10);
    Test.assertEqualMessage(
        app.getVibrationDuration(), app.MIN_VIBE_DURATION,
        "duration should clamp to the minimum"
    );

    app.setVibrationStrength(strength);
    app.setVibrationDuration(duration);
    Test.assertEqualMessage(app.getVibrationStrength(), strength, "failed to restore strength");
    Test.assertEqualMessage(app.getVibrationDuration(), duration, "failed to restore duration");
    return true;
}

// The strength scale must bottom out at 1%, not 0%. A cue the hardware might
// not be able to produce is the point of the setting; silence is not one of its
// values any more, so nothing may quietly reintroduce it.
(:test)
function settingsStrengthNeverReachesSilence(logger as Test.Logger) as Boolean {
    var app = getApp();
    var original = app.getVibrationStrength();

    Test.assertEqualMessage(
        app.MIN_VIBE_STRENGTH, 1,
        "the weakest cue is 1% -- 0% would be no vibration at all"
    );

    app.setVibrationStrength(-50);
    Test.assertMessage(
        app.getVibrationStrength() > 0,
        "no input may drive strength to 0%, got " + app.getVibrationStrength()
    );

    app.setVibrationStrength(original);
    return true;
}

// Walk each range end to end exactly as the tap controls do. Every value must
// stay inside the range and both endpoints must actually be reached -- this is
// the whole property clamping exists to provide.
(:test)
function settingsStepsWalkEveryRangeEndToEnd(logger as Test.Logger) as Boolean {
    var app = getApp();
    var pace = app.getPaceHundredths();
    var strength = app.getVibrationStrength();
    var duration = app.getVibrationDuration();

    // --- pace ---
    app.setPaceHundredths(app.MIN_PACE_HUNDREDTHS);
    var guard = 0;
    while (app.getPaceHundredths() < app.MAX_PACE_HUNDREDTHS && guard < 1000) {
        app.setPaceHundredths(app.getPaceHundredths() + app.PACE_STEP);
        Test.assertMessage(
            app.getPaceHundredths() <= app.MAX_PACE_HUNDREDTHS,
            "stepping up overshot the pace maximum: " + app.getPaceHundredths()
        );
        guard += 1;
    }
    Test.assertEqualMessage(
        app.getPaceHundredths(), app.MAX_PACE_HUNDREDTHS,
        "stepping up must reach the maximum pace"
    );
    logger.debug("pace: " + guard + " taps from floor to ceiling");

    // --- strength: the range that the step does not divide ---
    app.setVibrationStrength(app.MIN_VIBE_STRENGTH);
    guard = 0;
    while (app.getVibrationStrength() < app.MAX_VIBE_STRENGTH && guard < 1000) {
        app.setVibrationStrength(app.getVibrationStrength() + app.STRENGTH_STEP);
        Test.assertMessage(
            app.getVibrationStrength() <= app.MAX_VIBE_STRENGTH,
            "stepping up overshot 100%: " + app.getVibrationStrength()
        );
        guard += 1;
    }
    Test.assertEqualMessage(
        app.getVibrationStrength(), app.MAX_VIBE_STRENGTH,
        "stepping up by " + app.STRENGTH_STEP + " must still reach 100%"
    );
    logger.debug("strength: " + guard + " taps from floor to ceiling");

    guard = 0;
    while (app.getVibrationStrength() > app.MIN_VIBE_STRENGTH && guard < 1000) {
        app.setVibrationStrength(app.getVibrationStrength() - app.STRENGTH_STEP);
        Test.assertMessage(
            app.getVibrationStrength() >= app.MIN_VIBE_STRENGTH,
            "stepping down undershot the strength floor: " + app.getVibrationStrength()
        );
        guard += 1;
    }
    Test.assertEqualMessage(
        app.getVibrationStrength(), app.MIN_VIBE_STRENGTH,
        "stepping down must reach the 1% floor"
    );

    // --- length ---
    app.setVibrationDuration(app.MAX_VIBE_DURATION);
    guard = 0;
    while (app.getVibrationDuration() > app.MIN_VIBE_DURATION && guard < 1000) {
        app.setVibrationDuration(app.getVibrationDuration() - app.DURATION_STEP);
        Test.assertMessage(
            app.getVibrationDuration() >= app.MIN_VIBE_DURATION,
            "stepping down undershot the length floor: " + app.getVibrationDuration()
        );
        guard += 1;
    }
    Test.assertEqualMessage(
        app.getVibrationDuration(), app.MIN_VIBE_DURATION,
        "stepping down must reach the shortest length"
    );
    logger.debug("length: " + guard + " taps from ceiling to floor");

    app.setPaceHundredths(pace);
    app.setVibrationStrength(strength);
    app.setVibrationDuration(duration);
    return true;
}
