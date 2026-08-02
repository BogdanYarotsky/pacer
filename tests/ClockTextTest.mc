import Toybox.Lang;
import Toybox.Test;

(:test)
function clockTextPadsHoursAndMinutes(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        ClockText.formatTime(7, 5),
        "07:05",
        "single-digit clock fields should be zero-padded"
    );
    return true;
}

(:test)
function clockTextFormatsDayBoundaries(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(ClockText.formatTime(0, 0), "00:00", "midnight should be 00:00");
    Test.assertEqualMessage(ClockText.formatTime(23, 59), "23:59", "end of day should be 23:59");
    return true;
}
