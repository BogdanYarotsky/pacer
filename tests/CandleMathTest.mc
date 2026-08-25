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
// settingsStepsWalkEveryRangeEndToEnd: the ladder's edge requests -- 0% from
// the floor, 105% from the ceiling -- land back on the endpoints only if the
// setter clamps.

(:test)
function candleMathClampReturnsInRangeValuesUntouched(logger as Test.Logger) as Boolean {
    for (var v = 1; v <= 100; v += 1) {
        Test.assertEqualMessage(
            CandleMath.clamp(v, 1, 100), v,
            "clamp(" + v + ", 1, 100) should pass an in-range value through unchanged"
        );
    }
    return true;
}

(:test)
function candleMathClampIsExactAtBothBoundaries(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.clamp(1, 1, 100), 1, "the minimum itself is in range");
    Test.assertEqualMessage(CandleMath.clamp(100, 1, 100), 100, "the maximum itself is in range");
    Test.assertEqualMessage(CandleMath.clamp(0, 1, 100), 1, "one below the minimum clamps up");
    Test.assertEqualMessage(CandleMath.clamp(101, 1, 100), 100, "one above the maximum clamps down");
    return true;
}

// A degenerate single-value range must still terminate on that value rather
// than picking whichever bound the branches happen to reach first.
(:test)
function candleMathClampHandlesASingleValueRange(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.clamp(-5, 7, 7), 7, "below a single-value range");
    Test.assertEqualMessage(CandleMath.clamp(7, 7, 7), 7, "on a single-value range");
    Test.assertEqualMessage(CandleMath.clamp(99, 7, 7), 7, "above a single-value range");
    return true;
}

// Sweep every one of the app's real ranges, well past both ends, and assert the
// three properties that matter: the result is always inside the range, values
// inside are returned unchanged, and values outside land on the nearer bound.
(:test)
function candleMathClampHoldsAcrossEveryRealRange(logger as Test.Logger) as Boolean {
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
            var got = CandleMath.clamp(v, minimum, maximum);
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
function candleMathIntervalIsTenTimesTheValue(logger as Test.Logger) as Boolean {
    var app = getApp();
    Test.assertEqualMessage(
        CandleMath.intervalMillis(app.MIN_EVERY_HUNDREDTHS), 50,
        "the floor must be exactly the 50 ms Timer minimum");
    Test.assertEqualMessage(
        CandleMath.intervalMillis(app.DEFAULT_EVERY_HUNDREDTHS), 5000,
        "the default should be one cue every 5000 ms exactly");
    Test.assertEqualMessage(
        CandleMath.intervalMillis(525), 5250, "an off-ladder migrated value converts too");
    Test.assertEqualMessage(
        CandleMath.intervalMillis(app.MAX_EVERY_HUNDREDTHS), 15000,
        "the ceiling is 15 s between cues");
    logger.debug(
        "floor " + CandleMath.intervalMillis(app.MIN_EVERY_HUNDREDTHS) +
        " ms, ceiling " + CandleMath.intervalMillis(app.MAX_EVERY_HUNDREDTHS) + " ms");
    return true;
}

// Two cues per breath: the interval is half a breath, so twice the default
// interval is one full breath -- 10 s, 6 breaths a minute, 0.1 Hz, the Lehrer
// protocol's canonical frequency.
(:test)
function candleMathTwoCuesPerBreath(logger as Test.Logger) as Boolean {
    var app = getApp();
    var breathPeriodMs = 2 * CandleMath.intervalMillis(app.DEFAULT_EVERY_HUNDREDTHS);
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
function candleMathMigratesLegacyPaceTable(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.legacyPaceToEvery(600), 500, "6.00 bpm is a 5.00 s interval");
    Test.assertEqualMessage(CandleMath.legacyPaceToEvery(571), 525, "5.71 bpm rounds down to 5.25 s");
    Test.assertEqualMessage(CandleMath.legacyPaceToEvery(570), 526, "5.70 bpm rounds up to 5.26 s");
    Test.assertEqualMessage(CandleMath.legacyPaceToEvery(450), 667, "the old floor becomes 6.67 s");
    Test.assertEqualMessage(CandleMath.legacyPaceToEvery(700), 429, "the old ceiling becomes 4.29 s");
    return true;
}

// The fraction's LEADING zero is the one that actually bites: without it 6.05
// would render as "6.5" and read as a completely different pace. Trimming the
// trailing zeros must not touch it -- the two edits meet inside the same branch.
(:test)
function candleMathFormatsZeroPaddedFraction(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.formatHundredths(605), "6.05", "605 should format as 6.05");
    Test.assertEqualMessage(CandleMath.formatHundredths(501), "5.01", "501 should format as 5.01");
    Test.assertEqualMessage(CandleMath.formatHundredths(571), "5.71", "571 should format as 5.71");
    return true;
}

// Trailing zeros come off to cut clutter on the pace row: a hundredths digit of
// zero drops one place, and a fraction of zero drops the point as well.
(:test)
function candleMathTrimsTrailingZeros(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.formatHundredths(570), "5.7", "570 should trim to 5.7");
    Test.assertEqualMessage(CandleMath.formatHundredths(450), "4.5", "450 should trim to 4.5");
    Test.assertEqualMessage(CandleMath.formatHundredths(510), "5.1", "510 should trim to 5.1");
    Test.assertEqualMessage(CandleMath.formatHundredths(600), "6", "600 should trim to 6");
    Test.assertEqualMessage(CandleMath.formatHundredths(700), "7", "700 should trim to 7");
    Test.assertEqualMessage(CandleMath.formatHundredths(500), "5", "500 should trim to 5");
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
function candleMathFormatsEveryReachableInterval(logger as Test.Logger) as Boolean {
    var app = getApp();
    for (var v = app.MIN_EVERY_HUNDREDTHS; v <= app.MAX_EVERY_HUNDREDTHS; v += 1) {
        var s = CandleMath.formatHundredths(v);

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
function candleMathFormatsDuration(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.formatDuration(10), "10ms", "the duration floor");
    Test.assertEqualMessage(CandleMath.formatDuration(100), "100ms", "the default duration");
    Test.assertEqualMessage(CandleMath.formatDuration(250), "250ms", "the duration ceiling");
    return true;
}

(:test)
function candleMathFormatsStrength(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(CandleMath.formatStrength(1), "1%", "the strength floor");
    Test.assertEqualMessage(CandleMath.formatStrength(20), "20%", "the default strength");
    Test.assertEqualMessage(CandleMath.formatStrength(100), "100%", "the strength ceiling");
    return true;
}

// The POWER ladder: 5% rungs over the working range, 1% rungs at 5% and below.
// The zone boundary and the off-ladder snaps are the branches worth pinning --
// a wrong integer division here reads as "the + button sometimes jumps 9%" on
// a wrist, which is nearly impossible to diagnose from up there.
(:test)
function candleMathStrengthLadderStepsBothZones(logger as Test.Logger) as Boolean {
    // Fine zone, one percent at a time, and the boundary crossing both ways.
    Test.assertEqualMessage(CandleMath.strengthUp(1), 2, "1 steps to 2");
    Test.assertEqualMessage(CandleMath.strengthUp(4), 5, "4 steps to the fine limit");
    Test.assertEqualMessage(CandleMath.strengthUp(5), 10, "the fine limit steps to the first coarse rung");
    Test.assertEqualMessage(CandleMath.strengthDown(10), 5, "the first coarse rung steps back to the fine limit");
    Test.assertEqualMessage(CandleMath.strengthDown(5), 4, "the fine limit steps down by one");
    Test.assertEqualMessage(CandleMath.strengthDown(2), 1, "2 steps to the floor");

    // Coarse zone.
    Test.assertEqualMessage(CandleMath.strengthUp(20), 25, "the default steps by five");
    Test.assertEqualMessage(CandleMath.strengthDown(100), 95, "the ceiling steps down by five");

    // Off-ladder values, stored by earlier builds, snap in the tap's own
    // direction and are on the ladder from then on.
    Test.assertEqualMessage(CandleMath.strengthUp(14), 15, "14 snaps up to 15");
    Test.assertEqualMessage(CandleMath.strengthDown(14), 10, "14 snaps down to 10");
    Test.assertEqualMessage(CandleMath.strengthUp(99), 100, "99 snaps up to the ceiling");
    Test.assertEqualMessage(CandleMath.strengthDown(6), 5, "6 snaps down to the fine limit");

    // The edges ask past the range and rely on the setter's clamp.
    Test.assertEqualMessage(CandleMath.strengthUp(100), 105, "the ceiling asks past the top");
    Test.assertEqualMessage(CandleMath.strengthDown(1), 0, "the floor asks below the bottom");

    // The whole scale, both directions, exactly as a thumb walks it: 23 taps.
    var v = 1;
    var taps = 0;
    while (v < 100 && taps < 1000) {
        v = CandleMath.clamp(CandleMath.strengthUp(v), 1, 100);
        taps += 1;
    }
    Test.assertEqualMessage(taps, 23, "floor to ceiling should be 23 taps");
    taps = 0;
    while (v > 1 && taps < 1000) {
        v = CandleMath.clamp(CandleMath.strengthDown(v), 1, 100);
        taps += 1;
    }
    Test.assertEqualMessage(taps, 23, "ceiling to floor should be 23 taps");
    logger.debug("strength ladder: 23 taps each way");
    return true;
}

// The EVERY row is one bare number and its unit, pinned as a string because
// the row is read as one: a refactor that keeps the number right and moves the
// unit or reintroduces a space still changes what the screen says.
(:test)
function candleMathFormatsEvery(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        CandleMath.formatEvery(500), "5s", "the default trims to a bare 5s");
    Test.assertEqualMessage(
        CandleMath.formatEvery(510), "5.1s", "one trailing zero comes off");
    Test.assertEqualMessage(
        CandleMath.formatEvery(525), "5.25s", "a migrated measurement keeps both decimals");
    Test.assertEqualMessage(
        CandleMath.formatEvery(495), "4.95s", "one step below the default");
    Test.assertEqualMessage(
        CandleMath.formatEvery(5), "0.05s", "the floor keeps its leading zero");
    Test.assertEqualMessage(
        CandleMath.formatEvery(1000), "10s", "two digits of whole seconds");
    Test.assertEqualMessage(
        CandleMath.formatEvery(1495), "14.95s", "the widest string the row can show");
    Test.assertEqualMessage(
        CandleMath.formatEvery(1500), "15s", "the ceiling trims clean");
    return true;
}

// The battery reading is a Float and the screen is integers, so the whole of
// the arithmetic between them is a rounding and a clamp. Neither can be
// exercised on a real battery -- the simulator has no way to report 79.5% --
// which is exactly why the arithmetic lives in a pure function.
(:test)
function candleMathRoundsBatteryToNearestPercent(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        CandleMath.batteryPercent(80.0), 80, "a whole percentage passes through");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(79.4), 79, "below the half rounds down");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(79.5), 80, "the half rounds up, not toward zero");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(79.9), 80, "just under the next percent rounds up");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(0.0), 0, "a flat battery reads zero, not blank");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(0.4), 0, "a nearly flat battery still reads zero");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(100.0), 100, "a full battery reads 100");

    // The SDK documents the field as a percentage and says nothing about
    // bounds, so both ends clamp rather than print something impossible.
    Test.assertEqualMessage(
        CandleMath.batteryPercent(104.0), 100, "over 100 must pin at 100");
    Test.assertEqualMessage(
        CandleMath.batteryPercent(-3.0), 0, "under zero must pin at 0");

    // Monotonic across the whole range: a charge that goes up can never make
    // the displayed percentage go down.
    var previous = -1;
    for (var tenths = 0; tenths <= 1000; tenths += 1) {
        var shown = CandleMath.batteryPercent(tenths / 10.0);
        Test.assertMessage(
            shown >= previous,
            "battery " + (tenths / 10.0) + "% displayed " + shown +
                " after a lower charge displayed " + previous);
        Test.assertMessage(
            shown >= 0 && shown <= 100,
            "battery " + (tenths / 10.0) + "% displayed out of range: " + shown);
        previous = shown;
    }
    logger.debug("swept 1001 tenths of a percent, 0.0 through 100.0");
    return true;
}
