import Toybox.Lang;
import Toybox.Test;

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

// The supported band is 4.50-6.50 breaths/min. A faster pace must mean a
// shorter gap between cues.
(:test)
function pacerMathIntervalShrinksAsPaceRises(logger as Test.Logger) as Boolean {
    var slow = PacerMath.intervalMillis(450);
    var fast = PacerMath.intervalMillis(650);
    logger.debug("450 -> " + slow + " ms, 650 -> " + fast + " ms");
    Test.assertMessage(slow > fast, "a slower pace must give a longer interval");
    Test.assertEqualMessage(slow, 6667, "450 hundredths should give 6667 ms");
    Test.assertEqualMessage(fast, 4615, "650 hundredths should give 4615 ms");
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
    Test.assertEqualMessage(PacerMath.formatHundredths(650), "6.50", "650 should format as 6.50");
    return true;
}

// Every pace the picker can produce must format as N.NN -- four characters, one
// dot, two digits after it.
(:test)
function pacerMathFormatsEveryPaceInRange(logger as Test.Logger) as Boolean {
    for (var v = 450; v <= 650; v += 1) {
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
        "5.71 BPM (5.25 sec)",
        "default pace summary should include the cue interval"
    );
    Test.assertEqualMessage(
        PacerMath.formatPaceSummary(570),
        "5.70 BPM (5.26 sec)",
        "pace summary should derive the interval from the selected pace"
    );
    return true;
}
