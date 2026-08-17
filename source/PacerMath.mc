import Toybox.Lang;

// Pure pace arithmetic and value formatting, kept out of pacerApp so it is
// testable without a running application instance -- and so the layout tests
// measure the same strings the view draws rather than a second copy of them.
module PacerMath {

    // Constrain a value to an inclusive range.
    //
    // The settings setters clamp rather than reject, so a step that does not
    // divide its range evenly still reaches the endpoint instead of stalling one
    // step short of it.
    //
    // Every range now divides evenly by its own step, so a walk that starts on
    // the ladder lands exactly on both endpoints -- but a stored value need not
    // be on the ladder. Strength ran 1..100 by 2 until the floor moved to 2, so
    // every value that build ever wrote is odd, and from an odd value the tap
    // that should reach 100% asks for 101. Clamping is what lets such a value
    // walk back onto the ladder rather than stall one step short of an endpoint.
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

    // Render an integer number of hundredths as a decimal, with no trailing
    // zeros: 571 -> "5.71", 570 -> "5.7", 600 -> "6", 605 -> "6.05".
    //
    // The trailing zeros come off to cut clutter on the pace row, which is the
    // only line on the screen with decimals at all and the widest one on it. The
    // cost is that the line changes width as it is tapped through -- "6bpm | 5s"
    // is a good deal shorter than "5.71bpm | 5.25s" -- and, being centred, it
    // shifts under the thumb rather than growing to one side.
    //
    // What does NOT come off is the fraction's LEADING zero. Without it 605 would
    // render as "6.5" and read as a completely different pace, which is why the
    // padding branch is still here and still has a test to itself.
    //
    // Number / Number is integer division, and format("%02d") does the padding.
    function formatHundredths(value as Number) as String {
        var whole = (value / 100).toString();
        var fraction = value % 100;

        if (fraction == 0) {
            return whole;
        }
        if (fraction % 10 == 0) {
            return whole + "." + (fraction / 10).toString();
        }
        return whole + "." + fraction.format("%02d");
    }

    // Render the pace, and the half-breath cue interval it produces, for the
    // PACE row. Milliseconds to hundredths of a second, rounded to nearest.
    //
    // The pace leads: it is the number resonance-frequency protocols are written
    // in and the one a tap actually moves. The interval follows it past a divider
    // because it is the half of the pair you can check against a clock -- count
    // one gap between buzzes and you know the setting is what you think it is.
    //
    // Each number sits against its own unit with no space, so the eye splits the
    // line at the divider rather than at four separate gaps.
    //
    // Seconds are abbreviated to "s" rather than spelled "sec" for a measured
    // reason, not a stylistic one: "5.22 sec (5.75 bpm)" is 239 px in FONT_XTINY
    // and there are only 232 px between the "-" and "+" circles, so it drew on
    // top of both of them. The budget is Layout.editorTextMaxWidth and the guard
    // is layoutEveryReachableValueFits -- this is not a free string to lengthen.
    function formatPaceSummary(paceHundredths as Number) as String {
        var secondsHundredths = ((intervalMillis(paceHundredths) / 10.0) + 0.5).toNumber();
        return formatHundredths(paceHundredths)
            + "bpm | "
            + formatHundredths(secondsHundredths)
            + "s";
    }

    // Units sit tight against their numbers on every row -- "20%", "5s",
    // "100ms". The percent sign never takes a space in common usage, and one
    // rule for all three rows beats a per-row exception.
    function formatStrength(percent as Number) as String {
        return percent.toString() + "%";
    }

    function formatDuration(milliseconds as Number) as String {
        return milliseconds.toString() + "ms";
    }
}
