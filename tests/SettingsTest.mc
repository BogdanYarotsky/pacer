import Toybox.Lang;
import Toybox.Test;

// Settings behaviour that can only be observed through the real setters.
//
// The clamping arithmetic itself is tested purely in PacerMathTest -- it does
// not belong here, because every test in this file writes through to Storage and
// a test that writes to Storage can strand a value there. The one below is
// therefore the only one that does, and it restores from a `finally` so a failed
// assertion cannot leave the simulator holding the value it died on.

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

    // The strength scale bottoms out at the weakest cue the hardware can be
    // asked for, not at silence. Nothing may quietly reintroduce a mute.
    Test.assertEqualMessage(
        app.MIN_VIBE_STRENGTH, 1,
        "the weakest cue is 1% -- 0% would be no vibration at all");
    return true;
}

// Walk each range end to end exactly as the tap controls do. Every value must
// stay inside the range, and both endpoints must actually be reached.
//
// This is also the only coverage that the setters really clamp: STRENGTH_STEP is
// 2 over a 1..100 range, so stepping up lands on 99 and the next tap asks for
// 101. Reaching 100% at all is only possible if that request is clamped rather
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
