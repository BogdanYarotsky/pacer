import Toybox.Lang;

// Clock rendering, 12- and 24-hour. Pure, so every minute of the day is swept
// by a test rather than sampled. ADR-0030
module ClockText {

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
        return twelve.format("%d") + ":" + minuteText;
    }
}
