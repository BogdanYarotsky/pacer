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
    // A walk that starts on a ladder lands exactly on both endpoints -- but a
    // stored value need not be on today's ladder. Strength has run 1..100 by 2
    // and 2..100 by 2 in earlier builds, so an installed watch can hold values
    // today's taps would never write. Clamping at the ends, and the ladder
    // functions snapping in the tap's own direction, are what let such a value
    // walk back onto the ladder rather than stall beside an endpoint.
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

    // The POWER ladder is two zones: 5% steps over the working range, 1% steps
    // at 5% and below. The coarse step is what makes the scale walkable -- 100%
    // to the floor in two dozen taps -- and the fine zone exists because the
    // bottom of the scale is where the hardware's real threshold hides, and
    // finding it is the one job that needs single-percent resolution.
    const STRENGTH_FINE_LIMIT = 5;
    const STRENGTH_COARSE_STEP = 5;

    // One tap up / down the ladder. Deliberately unclamped: from 100% up asks
    // for 105 and from 1% down asks for 0, and the setter's clamp turns both
    // into the no-op they should be -- the same division of labour every other
    // step already uses.
    //
    // Integer division is what snaps an off-ladder value (a 14% stored by the
    // old 2% build) to the nearest rung in the tap's own direction: 14 up is
    // 15, 14 down is 10, and from then on the value is on the ladder.
    function strengthUp(value as Number) as Number {
        if (value < STRENGTH_FINE_LIMIT) {
            return value + 1;
        }
        return ((value / STRENGTH_COARSE_STEP) + 1) * STRENGTH_COARSE_STEP;
    }

    function strengthDown(value as Number) as Number {
        if (value <= STRENGTH_FINE_LIMIT) {
            return value - 1;
        }
        return ((value - 1) / STRENGTH_COARSE_STEP) * STRENGTH_COARSE_STEP;
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
