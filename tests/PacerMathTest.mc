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

// The fraction's LEADING zero is the one that actually bites: without it 6.05
// would render as "6.5" and read as a completely different pace. Trimming the
// trailing zeros must not touch it -- the two edits meet inside the same branch.
(:test)
function pacerMathFormatsZeroPaddedFraction(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.formatHundredths(605), "6.05", "605 should format as 6.05");
    Test.assertEqualMessage(PacerMath.formatHundredths(501), "5.01", "501 should format as 5.01");
    Test.assertEqualMessage(PacerMath.formatHundredths(571), "5.71", "571 should format as 5.71");
    return true;
}

// Trailing zeros come off to cut clutter on the pace row: a hundredths digit of
// zero drops one place, and a fraction of zero drops the point as well.
(:test)
function pacerMathTrimsTrailingZeros(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.formatHundredths(570), "5.7", "570 should trim to 5.7");
    Test.assertEqualMessage(PacerMath.formatHundredths(450), "4.5", "450 should trim to 4.5");
    Test.assertEqualMessage(PacerMath.formatHundredths(510), "5.1", "510 should trim to 5.1");
    Test.assertEqualMessage(PacerMath.formatHundredths(600), "6", "600 should trim to 6");
    Test.assertEqualMessage(PacerMath.formatHundredths(700), "7", "700 should trim to 7");
    Test.assertEqualMessage(PacerMath.formatHundredths(500), "5", "500 should trim to 5");
    return true;
}

// Every pace the editor can reach must render as a decimal that reads back as
// the value it came from, with no trailing zero left on it. Bounds come from the
// app rather than being repeated here: hardcoded 450/650 meant this sweep
// silently stopped covering the range the moment the ceiling moved.
//
// The round trip is the assertion that carries the weight, and it replaces a
// fixed "four characters, dot in position 1" shape that trimming makes false.
// Dropping trailing zeros and keeping the fraction's leading one are the same
// branch seen from two sides, and a string that reads back as the wrong number
// is the bug both are about: "6.5" for 605 has the right shape, no trailing
// zero, and is a different pace.
(:test)
function pacerMathFormatsEveryPaceInRange(logger as Test.Logger) as Boolean {
    var app = getApp();
    for (var v = app.MIN_PACE_HUNDREDTHS; v <= app.MAX_PACE_HUNDREDTHS; v += 1) {
        var s = PacerMath.formatHundredths(v);

        // String.toFloat is documented as Float or Null, so an unparseable
        // string is a failure in itself. The + 0.5 absorbs float error before
        // truncating -- "4.29" comes back as 4.2899998, not 4.29.
        var parsed = s.toFloat();
        Test.assertMessage(
            parsed != null,
            "formatHundredths(" + v + ") = '" + s + "' does not parse as a number"
        );
        var readBack = (((parsed as Float) * 100.0) + 0.5).toNumber();
        Test.assertEqualMessage(
            readBack, v,
            "formatHundredths(" + v + ") = '" + s + "' reads back as " + readBack
        );

        // Only a value with a fraction has a decimal point to leave a zero on.
        if (v % 100 != 0) {
            var last = s.substring(s.length() - 1, s.length());
            Test.assertMessage(
                last != null && !(last as String).equals("0"),
                "formatHundredths(" + v + ") = '" + s + "' still ends in a trailing zero"
            );
        }
    }
    return true;
}

// The pace leads and its cue interval follows past a divider. Both halves are
// pinned as one string, spacing included, because the row is read as one: a
// refactor that keeps the numbers right and moves a space, a unit or the divider
// still changes what the screen says.
(:test)
function pacerMathFormatsPaceSummary(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(571),
        "5.71bpm | 5.25s",
        "the default pace should lead, with its cue interval past the divider"
    );
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(570),
        "5.7bpm | 5.26s",
        "the interval must be derived from the selected pace"
    );
    // Both ends of the range, where the interval is longest and shortest -- and
    // both of them trim, which is where the line is at its shortest on screen.
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(450),
        "4.5bpm | 6.67s",
        "the slowest pace should give the longest interval"
    );
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(700),
        "7bpm | 4.29s",
        "the fastest pace should give the shortest interval"
    );
    // The one value where both halves trim away to whole numbers.
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(600),
        "6bpm | 5s",
        "6 breaths a minute is exactly one cue every five seconds"
    );
    return true;
}
