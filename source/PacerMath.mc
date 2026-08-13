import Toybox.Lang;

// Pure pace arithmetic and formatting, extracted from pacerApp so it can be
// unit tested without an running application instance. pacerApp delegates here;
// the behaviour is unchanged.
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
    function formatHundredths(value as Number) as String {
        var whole = (value / 100).toNumber();
        var fraction = value % 100;
        var fractionText = fraction.toString();

        if (fraction < 10) {
            fractionText = "0" + fractionText;
        }

        return whole.toString() + "." + fractionText;
    }

    // Render the pace and its half-breath cue interval for the PACE row.
    function formatPaceSummary(paceHundredths as Number) as String {
        var secondsHundredths = ((intervalMillis(paceHundredths) / 10.0) + 0.5).toNumber();
        return formatHundredths(paceHundredths)
            + " BPM / "
            + formatHundredths(secondsHundredths)
            + "s";
    }

    // The other two rows. These live here rather than inline in pacerApp so the
    // layout sweep in tests/LayoutTest.mc measures the same strings the view
    // draws instead of a second copy of the same format.
    function formatStrength(percent as Number) as String {
        return percent.toString() + "%";
    }

    function formatDuration(milliseconds as Number) as String {
        return milliseconds.toString() + " ms";
    }
}
