import Toybox.Lang;

// Pure cue arithmetic and value formatting, kept out of candleApp so it is
// testable without a running application instance -- and so the layout tests
// measure the same strings the view draws rather than a second copy of them.
module CandleMath {

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
    // It lives here, and not as a private helper on candleApp, so the arithmetic
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

    // THE STORED UNIT IS MILLISECONDS, and that is forced arithmetic rather
    // than taste. It was hundredths of a second until the PACE row's step went
    // to 0.01 bpm, which is the precision Yudemon reports a resonance frequency
    // at, and hundredths cannot hold it: 205 of the 801 rungs between 2.00 and
    // 10.00 bpm collide with their neighbour, the first pair being 5.53 and
    // 5.54 bpm, which both round to 5.42 s. Two hundred dead taps, starting in
    // the middle of the resonance band. In milliseconds all 801 are distinct
    // with 3 ms to spare at the tightest, which is 8.75 bpm.
    //
    // The cue timer takes milliseconds, so the stored number is now the number
    // the timer runs and `intervalMillis` is gone -- it converted hundredths to
    // milliseconds and would be the identity today.
    //
    // Each breath still gets two cues, one at each turn-around, so the interval
    // is half a breath: EVERY 5s is 10 s per breath, 0.1 Hz. The two cues are
    // identical on purpose -- with an equal I:E ratio the boundaries are
    // interchangeable, so the wrist feels a metronome at twice the breath rate
    // carrying no phase at all, which is what lets you rejoin on any pulse.
    // Read AGENTS.md before "improving" that.

    // Interval milliseconds from breaths-per-minute hundredths.
    //
    // Two cues per breath, so seconds between cues = 30 / bpm, and in each
    // unit's own hundredths and milliseconds:
    //     everyMillis = 3000000 / paceHundredths
    // The + 0.5 rounds to nearest, because Float.toNumber() truncates.
    //
    // The constant is the same in both directions -- everyToPace divides by the
    // same 3000000 -- because the relationship is a reciprocal and not a scale.
    // That is also why no pair of fixed steps can be even in both units, and
    // why each row gets the step that suits its own.
    //
    // This was `legacyPaceToEvery`, the one-time bridge from the retired pace
    // model whose STORED unit was bpm hundredths. That model came back on
    // 2026-08-25 as a second view rather than a second key, and the migration
    // calls the same function the PACE row does. There was never a second
    // formula here, only a second caller.
    function paceToEvery(paceHundredths as Number) as Number {
        return ((3000000.0 / paceHundredths) + 0.5).toNumber();
    }

    // The PACE row's value for a given interval, to the nearest 0.01 bpm.
    //
    // Rounding to the nearest rung is what makes a PACE tap reversible, because
    // candleApp.stepRow steps from the value on the glass rather than from the
    // one in Storage. Stepping from the stored interval instead would let "+"
    // then "-" land somewhere else.
    //
    // It rounds ONCE, at the resolution the row shows. The earlier 0.1 bpm
    // version had to round to a hundredth and then snap to a tenth, and got 60
    // of 1201 intervals wrong by a whole rung for it. At 0.01 bpm the rung IS
    // the hundredth, so there is nothing to snap and nothing to double-round --
    // the step going finer made this function simpler, not harder.
    //
    // Every rung from 2.00 to 10.00 bpm maps to a distinct interval and
    // survives the round trip back; settingsPaceAndEveryAreOneSettingTwoViews
    // walks all 801 of them rather than sampling.
    function everyToPace(everyMillis as Number) as Number {
        return ((3000000.0 / everyMillis) + 0.5).toNumber();
    }

    // One tap of the EVERY row's "-" or "+", SNAPPED to the ladder.
    //
    // This is the same shape as strengthUp/strengthDown below and exists for a
    // sharper version of the same reason. Adding the step to the current value
    // is only sound while the current value is on the ladder, and the PACE row
    // guarantees it is not: dial 5.73 bpm and the interval is 5237 ms, so a
    // plain +50 walks 5287, 5337, 5387 and never touches a round tenth again.
    // The wearer's own words for it: "I can't make it EVERY 5.1s without
    // guessing a proper PACE before that."
    //
    // Integer division snaps to the rung below, and the tap's own direction
    // decides which side of it you land: up from 5237 ms is 5250, down is 5200.
    // From then on the value is on the ladder and the steps are plain again.
    // The ladder is anchored at zero rather than at the floor, which is what
    // keeps both range endpoints on it -- 3000 and 15000 are both multiples.
    function everyUp(everyMillis as Number, step as Number) as Number {
        return ((everyMillis / step) + 1) * step;
    }

    function everyDown(everyMillis as Number, step as Number) as Number {
        return ((everyMillis - 1) / step) * step;
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

    // The EVERY row's value: the bare cue interval in seconds, which is the
    // number the timer actually runs.
    //
    // It carries no second number in parentheses, and that has survived the
    // arrival of the PACE row -- "5.22 sec (5.75 bpm)" is exactly the string
    // that used to draw over both control circles. Whoever thinks in breaths
    // per minute now has a ROW for it rather than a suffix, which is the same
    // information at a quarter of the width apiece.
    //
    // Seconds are abbreviated to "s" rather than spelled "sec" for a measured
    // reason, not a stylistic one: "5.22 sec (5.75 bpm)" was 239 px in
    // FONT_XTINY against fewer pixels than that between the "-" and "+"
    // circles, so it drew on top of both of them. The budget is
    // Layout.editorTextMaxWidth and the guard is layoutEveryReachableValueFits
    // -- this is not a free string to lengthen.
    // It reads at hundredths of a second, where the stored value is
    // milliseconds. That is a readout rounding and not a loss: the EVERY ladder
    // is 50 ms, so every value this row can set itself shows exactly. Only an
    // interval the PACE row put there can land between two hundredths -- 5.73
    // bpm is 5237 ms, drawn as "5.24s" -- and the underlying number stays
    // exact underneath it. Three decimals would be honest and would also make
    // this the widest line on the screen to report a millisecond nobody is
    // pacing to.
    function formatEvery(everyMillis as Number) as String {
        return formatHundredths(((everyMillis / 10.0) + 0.5).toNumber()) + "s";
    }

    // The PACE row's value: the same cue rate in breaths per minute.
    //
    // It goes through formatHundredths for the same reason EVERY does, so the
    // two rows read as one grammar and the trailing zeros come off both: 570 is
    // "5.7bpm" and 1000 is "10bpm", not "10.0bpm".
    //
    // "bpm" is spelled out where seconds are abbreviated to "s", and that costs
    // real pixels -- "PACE 9.9bpm" is the second-widest line the app can draw.
    // It fits, and it is the string the tools use; "PACE 9.9b" would save 20 px
    // and mean nothing to anyone. The ceiling is what keeps it affordable: a
    // pace above 9.9 would need two digits and a decimal, which is where this
    // row would become the widest thing on either screen and start pushing the
    // tap zones back. See candleApp.MAX_PACE_HUNDREDTHS.
    function formatPace(paceHundredths as Number) as String {
        return formatHundredths(paceHundredths) + "bpm";
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

    // System.Stats.battery is a Float percentage. This is the whole of the
    // arithmetic between it and the screen: round to nearest, and clamp.
    //
    // The + 0.5 rounds because Float.toNumber() truncates -- the same idiom
    // paceToEvery uses, for the same reason. The clamp is defensive
    // rather than expected: the SDK documents the field as a percentage and
    // says nothing about bounds, and a bottom line reading "BATTERY 104%" would
    // be a worse bug than a reading pinned at 100.
    //
    // It is here rather than in the view so the rounding is testable without a
    // battery -- there is no way to make the simulator report 79.5%.
    function batteryPercent(battery as Float) as Number {
        return clamp((battery + 0.5).toNumber(), 0, 100);
    }

    // Which of the three formatters a row's value goes through -- the one place
    // that mapping lives.
    //
    // It is here rather than on candleApp because measure-what-you-draw needs
    // it in both hands at once: the view asks the app for the value a row is
    // showing right now, while the layout sweep has to render every value a row
    // can ever show without a running app or a Storage write. Two copies of
    // this if-chain would be two chances for the sweep to measure a string the
    // screen does not draw, which is the drift Display.mc's header is about.
    function rowValueText(row as Number, value as Number) as String {
        if (row == Rows.EVERY) {
            return formatEvery(value);
        }
        if (row == Rows.PACE) {
            return formatPace(value);
        }
        if (row == Rows.PULSE) {
            return formatDuration(value);
        }
        return formatStrength(value);
    }
}
