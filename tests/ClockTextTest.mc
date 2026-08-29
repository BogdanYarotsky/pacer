import Toybox.Lang;
import Toybox.Test;

(:test)
function clockTextPadsHoursAndMinutes(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(ClockText.formatTime(7, 5, true), "07:05", "clock fields need padding");
    Test.assertEqualMessage(ClockText.formatTime(0, 0, true), "00:00", "midnight should be 00:00");
    Test.assertEqualMessage(ClockText.formatTime(23, 59, true), "23:59", "end of day should be 23:59");
    return true;
}

// The two ends of the 12-hour wrap are the cases that break: hour 0 must read
// 12 rather than 0, and hour 12 must stay 12 rather than wrap to 0.
(:test)
function clockTextWrapsTwelveHourMidnightAndNoon(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(ClockText.formatTime(0, 0, false), "12:00 AM", "midnight is 12:00 AM, not 0:00");
    Test.assertEqualMessage(ClockText.formatTime(12, 0, false), "12:00 PM", "noon is 12:00 PM -- the wrapped hour cannot tell it from midnight");
    Test.assertEqualMessage(ClockText.formatTime(13, 5, false), "1:05 PM", "13:05 is 1:05 PM");
    Test.assertEqualMessage(ClockText.formatTime(23, 59, false), "11:59 PM", "23:59 is 11:59 PM");
    Test.assertEqualMessage(ClockText.formatTime(9, 7, false), "9:07 AM", "12-hour mode does not pad the hour");
    return true;
}

// Every minute of every day, in both formats. A format that only breaks at
// 03:04 is exactly the kind that a handful of spot checks misses.
//
// 24-hour is hh:mm. 12-hour is h:mm or hh:mm plus a spaced AM/PM meridiem
// (ADR-0043), so its strings run three longer and end in a letter rather than a
// digit -- both asserted, because a suffix silently dropped in some branch is
// the failure this now has to catch as well.
(:test)
function clockTextFormatsEveryMinuteOfTheDay(logger as Test.Logger) as Boolean {
    var formats = [ true, false ];
    for (var f = 0; f < formats.size(); f += 1) {
        var is24Hour = formats[f] as Boolean;
        for (var hour = 0; hour < 24; hour += 1) {
            for (var minute = 0; minute < 60; minute += 1) {
                var s = ClockText.formatTime(hour, minute, is24Hour);
                var digits = is24Hour ? 5 : (hour % 12 == 0 || hour % 12 > 9 ? 5 : 4);
                var expectedLength = is24Hour ? digits : digits + 3;
                Test.assertEqualMessage(
                    s.length(), expectedLength,
                    "formatTime(" + hour + "," + minute + "," + is24Hour + ") = '" + s + "'"
                );

                // The colon sits third-from-last in 24-hour and sixth-from-last
                // in 12-hour, because the suffix comes after the minutes.
                var colonAt = is24Hour ? s.length() - 3 : s.length() - 6;
                var colon = s.substring(colonAt, colonAt + 1);
                Test.assertMessage(
                    colon != null && (colon as String).equals(":"),
                    "formatTime(" + hour + "," + minute + "," + is24Hour +
                        ") = '" + s + "' should have a colon before the minutes"
                );

                if (!is24Hour) {
                    var tail = s.substring(s.length() - 3, s.length()) as String;
                    var wanted = hour < 12 ? ClockText.SUFFIX_AM : ClockText.SUFFIX_PM;
                    Test.assertEqualMessage(
                        tail, wanted,
                        "formatTime(" + hour + "," + minute + ",false) = '" + s +
                            "' -- hour " + hour + " is " + (hour < 12 ? "AM" : "PM")
                    );
                }
            }
        }
    }
    return true;
}

// Noon and midnight both print "12:00" and are told apart ONLY by the suffix.
// This is the case the wrap hides: `hour % 12` is 0 for both, so anything
// deriving the meridiem from the wrapped hour gets one of them wrong and no
// digit on the screen shows it.
(:test)
function clockTextSeparatesNoonFromMidnight(logger as Test.Logger) as Boolean {
    var midnight = ClockText.formatTime(0, 0, false);
    var noon = ClockText.formatTime(12, 0, false);
    logger.debug("midnight '" + midnight + "'  noon '" + noon + "'");
    Test.assertMessage(
        !midnight.equals(noon),
        "midnight and noon both render '" + midnight + "' -- twelve hours apart " +
            "and indistinguishable on the glass");
    return true;
}
