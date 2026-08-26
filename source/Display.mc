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
    function rowText(row as Number, value as String) as String {
        return rowLabel(row) + " " + value;
    }

    // --- the main screen's bottom slot, in precedence order ------------------
    // ADR-0005

    // The only feedback a Back produces, now that Back does nothing. It names
    // the gesture that DOES work. ADR-0009
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

    // Drawn in EVERY build, unlike the version below: on a Store install this is
    // the only exit anything on the glass mentions. ADR-0010
    function backLabel() as String {
        return "BACK";
    }

    function buildLine(appVersion as String, showVersion as Boolean) as String {
        return showVersion ? "v" + appVersion : "";
    }

    // The PREDICATE is annotated, never buildLine itself. ADR-0031, ADR-0032
    (:debug)
    function showsBuildVersion() as Boolean {
        return true;
    }

    (:release)
    function showsBuildVersion() as Boolean {
        return false;
    }
}
