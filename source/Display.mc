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

    const APP_NAME = "Candle";

    // The settings screen's TITLE, in every build. ADR-0037
    //
    // It was `buildLine`, and it came with an annotated predicate that hid the
    // version from release builds -- the version was a developer's instrument
    // then, and drawing it for a wearer was duplication of what the Connect IQ
    // phone app already reports (ADR-0003). What changed is who reads it: a
    // wearer writing a bug report has the watch in hand and the phone app three
    // taps away on another device, and this band was empty anyway.
    //
    // So there is no predicate any more, no (:debug)/(:release) pair, and no
    // way for a release build to draw a different string from the one the tests
    // measure. The name is here because this is a title and titles are named;
    // it is NOT here to identify the app to its own wearer.
    function settingsTitle(appVersion as String) as String {
        return APP_NAME + " v" + appVersion;
    }
}
