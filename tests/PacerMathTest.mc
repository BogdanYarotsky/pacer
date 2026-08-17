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
        [app.MIN_EVERY_HUNDREDTHS, app.MAX_EVERY_HUNDREDTHS],
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

// --- cue arithmetic ---------------------------------------------------------

// The setting IS the interval, so the conversion is exactly ×10 -- hundredths
// of a second to milliseconds -- with nothing to round. The endpoints matter:
// the floor must land exactly on the platform's 50 ms Timer minimum, which is
// the reason the floor is the value it is.
(:test)
function pacerMathIntervalIsTenTimesTheValue(logger as Test.Logger) as Boolean {
    var app = getApp();
    Test.assertEqualMessage(
        PacerMath.intervalMillis(app.MIN_EVERY_HUNDREDTHS), 50,
        "the floor must be exactly the 50 ms Timer minimum");
    Test.assertEqualMessage(
        PacerMath.intervalMillis(app.DEFAULT_EVERY_HUNDREDTHS), 5000,
        "the default should be one cue every 5000 ms exactly");
    Test.assertEqualMessage(
        PacerMath.intervalMillis(525), 5250, "an off-ladder migrated value converts too");
    Test.assertEqualMessage(
        PacerMath.intervalMillis(app.MAX_EVERY_HUNDREDTHS), 15000,
        "the ceiling is 15 s between cues");
    logger.debug(
        "floor " + PacerMath.intervalMillis(app.MIN_EVERY_HUNDREDTHS) +
        " ms, ceiling " + PacerMath.intervalMillis(app.MAX_EVERY_HUNDREDTHS) + " ms");
    return true;
}

// Two cues per breath: the interval is half a breath, so twice the default
// interval is one full breath -- 10 s, 6 breaths a minute, 0.1 Hz, the Lehrer
// protocol's canonical frequency.
(:test)
function pacerMathTwoCuesPerBreath(logger as Test.Logger) as Boolean {
    var app = getApp();
    var breathPeriodMs = 2 * PacerMath.intervalMillis(app.DEFAULT_EVERY_HUNDREDTHS);
    logger.debug("default breath period = " + breathPeriodMs + " ms");
    Test.assertEqualMessage(
        breathPeriodMs, 10000,
        "two default cue intervals should be one 0.1 Hz breath");
    return true;
}

// The bridge from the retired pace model. These are the values real watches
// can hold: the shipped default, the measured pace that was once the default,
// its neighbour (which rounds the other way), and both ends of the old band.
// Migrated values land off the 0.05 s ladder on purpose -- the conversion
// preserves the wearer's measurement, and the next tap snaps to the ladder via
// the clamp, exactly like any other off-ladder stored value.
(:test)
function pacerMathMigratesLegacyPaceTable(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.legacyPaceToEvery(600), 500, "6.00 bpm is a 5.00 s interval");
    Test.assertEqualMessage(PacerMath.legacyPaceToEvery(571), 525, "5.71 bpm rounds down to 5.25 s");
    Test.assertEqualMessage(PacerMath.legacyPaceToEvery(570), 526, "5.70 bpm rounds up to 5.26 s");
    Test.assertEqualMessage(PacerMath.legacyPaceToEvery(450), 667, "the old floor becomes 6.67 s");
    Test.assertEqualMessage(PacerMath.legacyPaceToEvery(700), 429, "the old ceiling becomes 4.29 s");
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

// Every interval the editor can reach must render as a decimal that reads back
// as the value it came from, with no trailing zero left on it. Bounds come from
// the app rather than being repeated here: hardcoded 450/650 meant this sweep
// silently stopped covering the range the moment the ceiling moved.
//
// The round trip is the assertion that carries the weight, and it replaces a
// fixed "four characters, dot in position 1" shape that trimming makes false.
// Dropping trailing zeros and keeping the fraction's leading one are the same
// branch seen from two sides, and a string that reads back as the wrong number
// is the bug both are about: "6.5" for 605 has the right shape, no trailing
// zero, and is a different interval.
(:test)
function pacerMathFormatsEveryReachableInterval(logger as Test.Logger) as Boolean {
    var app = getApp();
    for (var v = app.MIN_EVERY_HUNDREDTHS; v <= app.MAX_EVERY_HUNDREDTHS; v += 1) {
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

// Units sit tight against their numbers -- one spacing rule for all three rows.
// "100 ms" shipped with a space for a while and was the only string on the
// screen with one; nothing pinned it, so nothing said so. These pins close that
// gap for both remaining formatters.
(:test)
function pacerMathFormatsDuration(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.formatDuration(10), "10ms", "the duration floor");
    Test.assertEqualMessage(PacerMath.formatDuration(100), "100ms", "the default duration");
    Test.assertEqualMessage(PacerMath.formatDuration(250), "250ms", "the duration ceiling");
    return true;
}

(:test)
function pacerMathFormatsStrength(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(PacerMath.formatStrength(2), "2%", "the strength floor");
    Test.assertEqualMessage(PacerMath.formatStrength(20), "20%", "the default strength");
    Test.assertEqualMessage(PacerMath.formatStrength(100), "100%", "the strength ceiling");
    return true;
}

// The EVERY row is one bare number and its unit, pinned as a string because
// the row is read as one: a refactor that keeps the number right and moves the
// unit or reintroduces a space still changes what the screen says.
(:test)
function pacerMathFormatsEvery(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        PacerMath.formatEvery(500), "5s", "the default trims to a bare 5s");
    Test.assertEqualMessage(
        PacerMath.formatEvery(510), "5.1s", "one trailing zero comes off");
    Test.assertEqualMessage(
        PacerMath.formatEvery(525), "5.25s", "a migrated measurement keeps both decimals");
    Test.assertEqualMessage(
        PacerMath.formatEvery(495), "4.95s", "one step below the default");
    Test.assertEqualMessage(
        PacerMath.formatEvery(5), "0.05s", "the floor keeps its leading zero");
    Test.assertEqualMessage(
        PacerMath.formatEvery(1000), "10s", "two digits of whole seconds");
    Test.assertEqualMessage(
        PacerMath.formatEvery(1495), "14.95s", "the widest string the row can show");
    Test.assertEqualMessage(
        PacerMath.formatEvery(1500), "15s", "the ceiling trims clean");
    return true;
}
