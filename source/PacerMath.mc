import Toybox.Lang;

// Pure cue arithmetic and value formatting, kept out of pacerApp so it is
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
    // The setting IS the cue interval, in hundredths of a second, so this is a
    // straight unit conversion with no rounding to go wrong. It used to be a
    // division -- the setting was breaths per minute and the screen translated
    // -- and retiring that translation is the point: the EVERY row shows the
    // bare number this function is fed.
    //
    // Each breath still gets two cues, one at each turn-around, so the interval
    // is half a breath: EVERY 5s is 10 s per breath, 0.1 Hz.
    //
    // The two cues are identical on purpose. With an equal I:E ratio the
    // boundaries are interchangeable, so what the wrist feels is a metronome at
    // twice the breath rate, carrying no phase at all -- which is exactly what
    // lets you rejoin on any pulse. Read AGENTS.md before "improving" that.
    function intervalMillis(everyHundredths as Number) as Number {
        return everyHundredths * 10;
    }

    // One-time bridge from the retired pace model, whose stored unit was
    // hundredths of a breath per minute. Interval hundredths from bpm
    // hundredths:
    //     (3000000 / paceHundredths) ms / 10  ==  300000 / paceHundredths
    // The + 0.5 rounds to nearest. Kept pure so the conversion table is
    // testable without touching Storage; pacerApp owns when it runs.
    function legacyPaceToEvery(paceHundredths as Number) as Number {
        return ((300000.0 / paceHundredths) + 0.5).toNumber();
    }

    // Render an integer number of hundredths as a decimal, with no trailing
    // zeros: 571 -> "5.71", 570 -> "5.7", 600 -> "6", 605 -> "6.05".
    //
    // The trailing zeros come off to cut clutter on the EVERY row, which is the
    // only line on the screen with decimals at all and the widest one on it. The
    // cost is that the line changes width as it is tapped through -- "5s" is a
    // good deal shorter than "5.25s" -- and, being centred, it shifts under the
    // thumb rather than growing to one side.
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

    // The EVERY row's value: the bare cue interval in seconds. No translation,
    // no second number -- whoever thinks in breaths per minute converts once,
    // outside the watch, and what they dial in here is the thing the timer runs.
    //
    // Seconds are abbreviated to "s" rather than spelled "sec" for a measured
    // reason, not a stylistic one: "5.22 sec (5.75 bpm)" was 239 px in
    // FONT_XTINY against fewer pixels than that between the "-" and "+"
    // circles, so it drew on top of both of them. The budget is
    // Layout.editorTextMaxWidth and the guard is layoutEveryReachableValueFits
    // -- this is not a free string to lengthen.
    function formatEvery(everyHundredths as Number) as String {
        return formatHundredths(everyHundredths) + "s";
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
