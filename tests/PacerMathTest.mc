import Toybox.Lang;
import Toybox.Test;

// --- clamp ------------------------------------------------------------------
//
// These are the tests that used to drive the real setters and therefore write to
// Storage. Pure arithmetic needs neither, so a killed simulator or a crashed run
// can no longer leave a value stranded in the simulator's persisted state -- the
// way an earlier deliberately-failed run left it holding 6.50 BPM at 99%.
//
// Coverage of the setters actually calling this lives in
// settingsStepsWalkEveryRangeEndToEnd, which reaches 100% from 99 + 2 and can
// only do so if the setter clamps.

(:test)
function pacerMathClampReturnsInRangeValuesUntouched(logger as Test.Logger) as Boolean {
    for (var v = 1; v <= 100; v += 1) {
        Test.assertEqualMessage(
            PacerMath.clamp(v, 1, 100), v,
            "clamp(" + v + ", 1, 100) should pass an in-range value through unchanged"
        );
    }
    return true;
}

(:test)
function pacerMathClampIsExactAtBothBoundaries(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.clamp(1, 1, 100), 1, "the minimum itself is in range");
    Test.assertEqualMessage(PacerMath.clamp(100, 1, 100), 100, "the maximum itself is in range");
    Test.assertEqualMessage(PacerMath.clamp(0, 1, 100), 1, "one below the minimum clamps up");
    Test.assertEqualMessage(PacerMath.clamp(101, 1, 100), 100, "one above the maximum clamps down");
    return true;
}

// A degenerate single-value range must still terminate on that value rather
// than picking whichever bound the branches happen to reach first.
(:test)
function pacerMathClampHandlesASingleValueRange(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.clamp(-5, 7, 7), 7, "below a single-value range");
    Test.assertEqualMessage(PacerMath.clamp(7, 7, 7), 7, "on a single-value range");
    Test.assertEqualMessage(PacerMath.clamp(99, 7, 7), 7, "above a single-value range");
    return true;
}

// Sweep every one of the app's real ranges, well past both ends, and assert the
// three properties that matter: the result is always inside the range, values
// inside are returned unchanged, and values outside land on the nearer bound.
(:test)
function pacerMathClampHoldsAcrossEveryRealRange(logger as Test.Logger) as Boolean {
    var app = getApp();
    var ranges = [
        [app.MIN_PACE_HUNDREDTHS, app.MAX_PACE_HUNDREDTHS],
        [app.MIN_VIBE_STRENGTH, app.MAX_VIBE_STRENGTH],
        [app.MIN_VIBE_DURATION, app.MAX_VIBE_DURATION]
    ];

    for (var r = 0; r < ranges.size(); r += 1) {
        var range = ranges[r] as Array<Number>;
        var minimum = range[0];
        var maximum = range[1];
        logger.debug("clamp sweep over " + minimum + ".." + maximum);

        for (var v = minimum - 50; v <= maximum + 50; v += 1) {
            var got = PacerMath.clamp(v, minimum, maximum);
            Test.assertMessage(
                got >= minimum && got <= maximum,
                "clamp(" + v + ", " + minimum + ", " + maximum + ") = " + got + " is out of range"
            );
            if (v < minimum) {
                Test.assertEqualMessage(got, minimum, "clamp(" + v + ") should be the minimum");
            } else if (v > maximum) {
                Test.assertEqualMessage(got, maximum, "clamp(" + v + ") should be the maximum");
            } else {
                Test.assertEqualMessage(got, v, "clamp(" + v + ") should be unchanged");
            }
        }
    }
    return true;
}

// --- pace arithmetic --------------------------------------------------------

// The default pace of 5.71 breaths/min is a personally measured resonance
// frequency. 3000000 / 571 = 5253.94..., which must round to 5254 rather than
// truncate to 5253 -- at ~11 cues a minute a 1ms truncation is harmless, but the
// rounding is the part that is easy to break silently during a refactor.
(:test)
function pacerMathIntervalAtDefaultPace(logger as Test.Logger) as Boolean {
    var ms = PacerMath.intervalMillis(571);
    logger.debug("intervalMillis(571) = " + ms);
    Test.assertEqualMessage(ms, 5254, "571 hundredths should give 5254 ms");
    return true;
}

// The supported band is 4.50-7.00 breaths/min, the range assessment protocols
// sweep. A faster pace must mean a shorter gap between cues.
(:test)
function pacerMathIntervalShrinksAsPaceRises(logger as Test.Logger) as Boolean {
    var slow = PacerMath.intervalMillis(450);
    var fast = PacerMath.intervalMillis(700);
    logger.debug("450 -> " + slow + " ms, 700 -> " + fast + " ms");
    Test.assertMessage(slow > fast, "a slower pace must give a longer interval");
    Test.assertEqualMessage(slow, 6667, "450 hundredths should give 6667 ms");
    Test.assertEqualMessage(fast, 4286, "700 hundredths should give 4286 ms");
    return true;
}

// Two cues per breath: the interval is half a breath, so twice the interval is
// one full breath period.
(:test)
function pacerMathTwoCuesPerBreath(logger as Test.Logger) as Boolean {
    var breathsPerMin = 6.0;
    var ms = PacerMath.intervalMillis(600);
    var breathPeriodMs = 2 * ms;
    var expected = 60000 / breathsPerMin;   // 10000 ms per breath at 6/min
    logger.debug("breath period = " + breathPeriodMs + " ms, expected " + expected);
    Test.assertMessage(
        (breathPeriodMs - expected).abs() <= 1,
        "two cue intervals should equal one breath period"
    );
    return true;
}

// The zero-padding branch is the one that actually bites: without it 6.05 would
// render as "6.5" and read as a completely different pace.
(:test)
function pacerMathFormatsZeroPaddedFraction(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.formatHundredths(605), "6.05", "605 should format as 6.05");
    Test.assertEqualMessage(PacerMath.formatHundredths(600), "6.00", "600 should format as 6.00");
    Test.assertEqualMessage(PacerMath.formatHundredths(571), "5.71", "571 should format as 5.71");
    Test.assertEqualMessage(PacerMath.formatHundredths(450), "4.50", "450 should format as 4.50");
    Test.assertEqualMessage(PacerMath.formatHundredths(700), "7.00", "700 should format as 7.00");
    return true;
}

// Every pace the editor can reach must format as N.NN -- four characters, one
// dot, two digits after it. Bounds come from the app rather than being repeated
// here: hardcoded 450/650 meant this sweep silently stopped covering the range
// the moment the ceiling moved.
(:test)
function pacerMathFormatsEveryPaceInRange(logger as Test.Logger) as Boolean {
    var app = getApp();
    for (var v = app.MIN_PACE_HUNDREDTHS; v <= app.MAX_PACE_HUNDREDTHS; v += 1) {
        var s = PacerMath.formatHundredths(v);
        Test.assertEqualMessage(
            s.length(), 4,
            "formatHundredths(" + v + ") = '" + s + "' should be 4 characters"
        );
        // substring returns String?, so narrow it before comparing.
        var dot = s.substring(1, 2);
        Test.assertMessage(
            dot != null && (dot as String).equals("."),
            "formatHundredths(" + v + ") = '" + s + "' should have a dot in position 1"
        );
    }
    return true;
}

(:test)
function pacerMathFormatsPaceSummary(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(571),
        "5.71 BPM / 5.25s",
        "default pace summary should include the cue interval"
    );
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(570),
        "5.70 BPM / 5.26s",
        "pace summary should derive the interval from the selected pace"
    );
    return true;
}
