import Toybox.Lang;

// Pure cue arithmetic and value formatting. No application instance, no Dc, so
// all of it is swept exhaustively by tests rather than sampled. ADR-0030
module CandleMath {

    // Clamp rather than reject, so a step off the end is the no-op it should be
    // and an endpoint stays reachable from a value off today's ladder. ADR-0026
    function clamp(value as Number, minimum as Number, maximum as Number) as Number {
        if (value < minimum) {
            return minimum;
        }
        if (value > maximum) {
            return maximum;
        }
        return value;
    }

    // --- the two units of one setting ---------------------------------------
    //
    // Interval MILLISECONDS, and hundredths of a breath per minute. Each range
    // is the other's exact reciprocal image. The same constant appears in both
    // directions because the relationship is a reciprocal and not a scale --
    // which is also why no pair of fixed steps can be even in both units, and
    // why each row gets the step that suits its own. ADR-0018, ADR-0019
    //
    // The + 0.5 rounds to nearest, because Float.toNumber() truncates.

    function paceToEvery(paceHundredths as Number) as Number {
        return ((3000000.0 / paceHundredths) + 0.5).toNumber();
    }

    // Rounds ONCE, at the resolution the row shows. That is what makes a PACE
    // tap reversible, since the tap steps from the value on the glass rather
    // than from the one in Storage. ADR-0019
    function everyToPace(everyMillis as Number) as Number {
        return ((3000000.0 / everyMillis) + 0.5).toNumber();
    }

    // One EVERY tap, SNAPPED to the ladder rather than added to the value.
    // Integer division snaps to the rung below and the tap's own direction
    // picks the side. Both step outside the range at the ends on purpose; the
    // setter's clamp brings them back. ADR-0021, ADR-0026
    function everyUp(everyMillis as Number, step as Number) as Number {
        return ((everyMillis / step) + 1) * step;
    }

    function everyDown(everyMillis as Number, step as Number) as Number {
        return ((everyMillis - 1) / step) * step;
    }

    // --- formatting -----------------------------------------------------------

    // Trailing zeros come off. The fraction's LEADING zero does not: without it
    // 605 would render as "6.5" and read as a different pace entirely, which is
    // why that branch has a test to itself.
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

    // Reads at hundredths of a second where the value is stored to the
    // millisecond, so an interval the PACE row put between two hundredths is
    // ROUNDED for display and stays exact underneath. ADR-0018
    //
    // "s" and not "sec", and no second number in parentheses: this row's width
    // is not free. ADR-0013
    function formatEvery(everyMillis as Number) as String {
        return formatHundredths(((everyMillis / 10.0) + 0.5).toNumber()) + "s";
    }

    // "5.88 BPM", and the unit is doing two jobs: it is the reading AND the
    // row's caption. This row draws no "PACE" label -- ADR-0038 -- so the unit
    // has to carry the sentence on its own, which is why it is spaced off the
    // number and set in capitals like the labels on the other three rows.
    function formatPace(paceHundredths as Number) as String {
        return formatHundredths(paceHundredths) + " BPM";
    }

    // --- the POWER ladder ------------------------------------------------------
    // Two zones, with integer division snapping an off-ladder value in the
    // tap's own direction. ADR-0023
    const STRENGTH_FINE_LIMIT = 5;
    const STRENGTH_COARSE_STEP = 5;

    // Deliberately unclamped at both ends -- the setter clamps. ADR-0026
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

    // Units sit tight against their numbers on every row. One rule for all of
    // them beats a per-row exception.
    function formatStrength(percent as Number) as String {
        return percent.toString() + "%";
    }

    function formatDuration(milliseconds as Number) as String {
        return milliseconds.toString() + "ms";
    }

    // The + 0.5 rounds because Float.toNumber() truncates. The clamp is
    // defensive rather than expected: the SDK documents the field as a
    // percentage and says nothing about bounds, and a bottom line reading over
    // 100% would be a worse bug than one pinned at it. Here rather than in the
    // view so the rounding is testable without a battery. ADR-0030
    function batteryPercent(battery as Float) as Number {
        return clamp((battery + 0.5).toNumber(), 0, 100);
    }

    // Which formatter a row's value goes through -- the one place that mapping
    // lives, because the view needs it for the value a watch is holding and the
    // layout sweep needs it for every value a watch could hold. ADR-0029
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
