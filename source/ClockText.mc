import Toybox.Lang;

// Clock rendering, kept pure so it is testable without a graphics context or a
// running clock. System.getClockTime() always reports a 24-hour hour; whether
// the user wants to *see* it that way is a separate device setting.
module ClockText {

    // is24Hour comes from System.getDeviceSettings().is24Hour.
    //
    // 12-hour mode drops the leading zero on the hour, as every Garmin watch
    // face does, and maps hour 0 to 12. No AM/PM suffix: this clock is context
    // for a breathing session, not a timekeeping display, and the marker would
    // cost width on the narrowest part of a round screen.
    function formatTime(hour as Number, minute as Number, is24Hour as Boolean) as String {
        var minuteText = minute.format("%02d");

        if (is24Hour) {
            return hour.format("%02d") + ":" + minuteText;
        }

        var twelve = hour % 12;
        if (twelve == 0) {
            twelve = 12;
        }
        return twelve.format("%d") + ":" + minuteText;
    }
}
