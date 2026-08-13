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
    Test.assertEqualMessage(ClockText.formatTime(0, 0, false), "12:00", "midnight is 12:00, not 0:00");
    Test.assertEqualMessage(ClockText.formatTime(12, 0, false), "12:00", "noon is 12:00, not 0:00");
    Test.assertEqualMessage(ClockText.formatTime(13, 5, false), "1:05", "13:05 is 1:05");
    Test.assertEqualMessage(ClockText.formatTime(23, 59, false), "11:59", "23:59 is 11:59");
    Test.assertEqualMessage(ClockText.formatTime(9, 7, false), "9:07", "12-hour mode does not pad the hour");
    return true;
}

// Every minute of every day must render as h:mm or hh:mm -- one colon, exactly
// two digits after it -- in both formats. A format that only breaks at 03:04 is
// exactly the kind that a handful of spot checks misses.
(:test)
function clockTextFormatsEveryMinuteOfTheDay(logger as Test.Logger) as Boolean {
    var formats = [ true, false ];
    for (var f = 0; f < formats.size(); f += 1) {
        var is24Hour = formats[f] as Boolean;
        for (var hour = 0; hour < 24; hour += 1) {
            for (var minute = 0; minute < 60; minute += 1) {
                var s = ClockText.formatTime(hour, minute, is24Hour);
                var expectedLength = is24Hour ? 5 : (hour % 12 == 0 || hour % 12 > 9 ? 5 : 4);
                Test.assertEqualMessage(
                    s.length(), expectedLength,
                    "formatTime(" + hour + "," + minute + "," + is24Hour + ") = '" + s + "'"
                );
                var colon = s.substring(s.length() - 3, s.length() - 2);
                Test.assertMessage(
                    colon != null && (colon as String).equals(":"),
                    "formatTime(" + hour + "," + minute + "," + is24Hour +
                        ") = '" + s + "' should have a colon before the minutes"
                );
            }
        }
    }
    return true;
}
