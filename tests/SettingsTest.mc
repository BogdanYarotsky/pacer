import Toybox.Lang;
import Toybox.Test;

// The setters clamp to the supported range instead of rejecting an out-of-range
// value, and these tests exist because the strength row now depends on it:
// STRENGTH_STEP is 2 over a 1..100 range, which does not divide evenly. Stepping
// up lands on 99, and the next tap asks for 101. Rejecting that would leave 100%
// permanently unreachable, with the "+" control going dead one step short of the
// top and nothing on screen to explain why.
//
// These tests write through to Storage, because that is the behaviour under
// test. Every one of them restores what it found from a `finally`, not from the
// end of the happy path: a failing assertion throws, and a restore that only
// runs on success leaves the simulator holding whatever value the test died on
// for every run after it.

function snapshotSettings(app as pacerApp) as Array<Number> {
    return [
        app.getPaceHundredths(),
        app.getVibrationStrength(),
        app.getVibrationDuration()
    ] as Array<Number>;
}

function restoreSettings(app as pacerApp, saved as Array<Number>) as Void {
    app.setPaceHundredths(saved[0]);
    app.setVibrationStrength(saved[1]);
    app.setVibrationDuration(saved[2]);
}

(:test)
function settingsClampToBothEndsOfEveryRange(logger as Test.Logger) as Boolean {
    var app = getApp();
    var saved = snapshotSettings(app);

    try {
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
            "length should clamp to the maximum"
        );
        app.setVibrationDuration(app.MIN_VIBE_DURATION - 10);
        Test.assertEqualMessage(
            app.getVibrationDuration(), app.MIN_VIBE_DURATION,
            "length should clamp to the minimum"
        );
    } finally {
        restoreSettings(app, saved);
    }

    Test.assertEqualMessage(
        app.getPaceHundredths(), saved[0], "the pace was not restored"
    );
    Test.assertEqualMessage(
        app.getVibrationStrength(), saved[1], "the strength was not restored"
    );
    Test.assertEqualMessage(
        app.getVibrationDuration(), saved[2], "the length was not restored"
    );
    return true;
}

// The strength scale must bottom out at 1%, not 0%. A cue the hardware might not
// be able to produce is the point of that setting; silence is not one of its
// values any more, so nothing may quietly reintroduce it.
(:test)
function settingsStrengthNeverReachesSilence(logger as Test.Logger) as Boolean {
    var app = getApp();
    var saved = snapshotSettings(app);

    try {
        Test.assertEqualMessage(
            app.MIN_VIBE_STRENGTH, 1,
            "the weakest cue is 1% -- 0% would be no vibration at all"
        );
        app.setVibrationStrength(-50);
        Test.assertMessage(
            app.getVibrationStrength() > 0,
            "no input may drive strength to 0%, got " + app.getVibrationStrength()
        );
    } finally {
        restoreSettings(app, saved);
    }
    return true;
}

// Walk each range end to end exactly as the tap controls do. Every value must
// stay inside the range, and both endpoints must actually be reached -- that is
// the whole property clamping exists to provide.
(:test)
function settingsStepsWalkEveryRangeEndToEnd(logger as Test.Logger) as Boolean {
    var app = getApp();
    var saved = snapshotSettings(app);

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

        // The range whose step does not divide it: 1..100 by 2.
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
            "stepping down must reach the 1% floor"
        );

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
        restoreSettings(app, saved);
    }
    return true;
}
