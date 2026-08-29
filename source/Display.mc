import Toybox.Lang;

// Every string the screens draw, in one place, so the layout tests measure what
// the view actually draws. ADR-0029
module Display {

    // Display words only, deliberately decoupled from the storage keys these
    // settings are saved under. ADR-0029, ADR-0025
    const LABEL_EVERY = "EVERY";
    const LABEL_PULSE = "PULSE";
    const LABEL_POWER = "POWER";
    const LABEL_PACE = "PACE";
    const LABEL_BATTERY = "BATTERY";

    // By row identity, never by position -- which is what let a row move to a
    // screen of its own without a single string changing. ADR-0028
    function rowLabel(row as Number) as String {
        if (row == Rows.EVERY) {
            return LABEL_EVERY;
        }
        if (row == Rows.PACE) {
            return LABEL_PACE;
        }
        if (row == Rows.PULSE) {
            return LABEL_PULSE;
        }
        return LABEL_POWER;
    }

    // Composed here and nowhere else. A second copy of this concatenation in
    // the view or in a test is the exact drift ADR-0029 is about.
    //
    // THE PACE ROW DRAWS NO CAPTION. Its unit is its caption -- the row reads
    // "5.88 BPM" and anyone who knows what a resonance frequency is needs no
    // more, while anyone who does not is meant to work the EVERY row above and
    // watch this one follow it. ADR-0038
    //
    // rowLabel(PACE) still returns "PACE": the label is the row's NAME, which
    // the delegate's traces and the input tests identify it by, and only three
    // of the four rows also draw theirs.
    function rowText(row as Number, value as String) as String {
        if (row == Rows.PACE) {
            return value;
        }
        return rowLabel(row) + " " + value;
    }

    // --- the bottom slot ------------------------------------------------------
    // Main screen: hint, then warning, then the battery, in that precedence
    // (ADR-0005). Settings screen: the hint alone, and empty otherwise
    // (ADR-0036).

    // The only feedback a Back produces, now that Back does nothing. It names
    // the gesture that DOES work, and it says the same thing on both screens
    // because a held lower button exits from either. ADR-0009, ADR-0036
    function exitHint() as String {
        return "HOLD TO EXIT";
    }

    // Empty when the watch is in order, and that empty string is what hands the
    // slot to the battery -- so a routine reading can never crowd out the
    // warning. ADR-0005
    function vibeWarning(willVibrate as Boolean) as String {
        return willVibrate ? "" : "VIBE OFF";
    }

    function batteryLine(percent as Number) as String {
        return LABEL_BATTERY + " " + percent.toString() + "%";
    }

    // --- the settings screen -------------------------------------------------
    //
    // There was a backLabel() here, drawn in every build. ADR-0036 deleted the
    // control it labelled: the upper button cycles the screens, so the bottom
    // band it occupied is the exit hint's now.

    // The settings screen's version, along its BOTTOM band, in every build.
    // ADR-0037 for why it is drawn at all, ADR-0040 for why it is down there
    // and why it is no longer the app's name.
    //
    // It read "Candle v1.0" and lived at the top until the logo took that band.
    // The name went with the move rather than being duplicated beside the mark:
    // a logo that needs its own name written next to it is not doing its job,
    // and the two bands are meant to balance -- one small thing at each end of
    // the screen, with the rows between them.
    //
    // There is no annotated predicate here and there must not be one: a
    // (:debug)/(:release) pair would let a store build draw a string no test
    // ever measured.
    function settingsVersion(appVersion as String) as String {
        return "v" + appVersion;
    }
}
