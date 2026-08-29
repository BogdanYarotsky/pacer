import Toybox.Lang;

// Clock rendering, 12- and 24-hour. Pure, so every minute of the day is swept
// by a test rather than sampled. ADR-0030
module ClockText {

    // The full "AM"/"PM", spaced, because that is what a clock says. It fits
    // only because the clock is FONT_SMALL rather than FONT_MEDIUM: one size
    // down buys 12 px of chord at the top slot's tightest point, and
    // "12:48 PM" needs it. ADR-0043 has the measurements and why a one-letter
    // suffix was tried first.
    const SUFFIX_AM = " AM";
    const SUFFIX_PM = " PM";

    function formatTime(hour as Number, minute as Number, is24Hour as Boolean) as String {
        var minuteText = minute.format("%02d");
        if (is24Hour) {
            return hour.format("%02d") + ":" + minuteText;
        }

        // 12-hour wraps BOTH ends: hour 0 and hour 12 are both "12".
        var twelve = hour % 12;
        if (twelve == 0) {
            twelve = 12;
        }

        // The suffix keys off the RAW hour, not the wrapped one -- 12 wraps to
        // 12 from both noon and midnight, so the wrapped value cannot tell them
        // apart. This is the half of the 12-hour wrap that has no visible
        // symptom in the number itself.
        var suffix = hour < 12 ? SUFFIX_AM : SUFFIX_PM;
        return twelve.format("%d") + ":" + minuteText + suffix;
    }
}
