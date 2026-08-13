import Toybox.Lang;

// Pure pace arithmetic and value formatting, kept out of pacerApp so it is
// testable without a running application instance -- and so the layout tests
// measure the same strings the view draws rather than a second copy of them.
module PacerMath {

    // Milliseconds between vibration cues.
    //
    // Each breath gets two cues, one at each inhale/exhale boundary, so a cue
    // interval is half a breath:
    //     60000 / (paceHundredths / 100) / 2  ==  3000000 / paceHundredths
    // The + 0.5 rounds to nearest rather than truncating.
    function intervalMillis(paceHundredths as Number) as Number {
        return ((3000000.0 / paceHundredths) + 0.5).toNumber();
    }

    // Render an integer number of hundredths as "N.NN".
    // 571 -> "5.71", 600 -> "6.00", 605 -> "6.05".
    //
    // Number / Number is integer division, and format("%02d") is the same
    // zero-padding ClockText uses -- the hand-rolled "if under ten, prepend a
    // zero" it replaces was a second idiom for one job.
    function formatHundredths(value as Number) as String {
        return (value / 100).toString() + "." + (value % 100).format("%02d");
    }

    // Render the pace and its half-breath cue interval for the PACE row.
    // Milliseconds to hundredths of a second, rounded to nearest.
    function formatPaceSummary(paceHundredths as Number) as String {
        var secondsHundredths = ((intervalMillis(paceHundredths) / 10.0) + 0.5).toNumber();
        return formatHundredths(paceHundredths)
            + " BPM / "
            + formatHundredths(secondsHundredths)
            + "s";
    }

    function formatStrength(percent as Number) as String {
        return percent.toString() + "%";
    }

    function formatDuration(milliseconds as Number) as String {
        return milliseconds.toString() + " ms";
    }
}
