import Toybox.Lang;

// Pure pace arithmetic and value formatting, kept out of pacerApp so it is
// testable without a running application instance -- and so the layout tests
// measure the same strings the view draws rather than a second copy of them.
module PacerMath {

    // Constrain a value to an inclusive range.
    //
    // The settings setters clamp rather than reject, so a step that does not
    // divide its range evenly still reaches the endpoint instead of stalling one
    // step short of it -- STRENGTH_STEP is 2 over a 1..100 range, and rejecting
    // the 101 that follows 99 would put 100% out of reach entirely.
    //
    // It lives here, and not as a private helper on pacerApp, so the arithmetic
    // can be tested exhaustively without writing a single value to Storage.
    function clamp(value as Number, minimum as Number, maximum as Number) as Number {
        if (value < minimum) {
            return minimum;
        }
        if (value > maximum) {
            return maximum;
        }
        return value;
    }

    // Milliseconds between vibration cues.
    //
    // Each breath gets two cues, one at each turn-around, so a cue interval is
    // half a breath:
    //     60000 / (paceHundredths / 100) / 2  ==  3000000 / paceHundredths
    // The + 0.5 rounds to nearest rather than truncating.
    //
    // The two cues are identical on purpose. With an equal I:E ratio the
    // boundaries are interchangeable, so what the wrist feels is a metronome at
    // twice the breath rate, carrying no phase at all -- which is exactly what
    // lets you rejoin on any pulse. Read AGENTS.md before "improving" that.
    function intervalMillis(paceHundredths as Number) as Number {
        return ((3000000.0 / paceHundredths) + 0.5).toNumber();
    }

    // Render an integer number of hundredths as "N.NN".
    // 571 -> "5.71", 600 -> "6.00", 605 -> "6.05".
    //
    // Number / Number is integer division, and format("%02d") does the padding.
    // The hand-rolled "if under ten, prepend a zero" this replaced was a second
    // idiom for a job the Lang built-in already did.
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
