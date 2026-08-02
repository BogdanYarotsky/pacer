import Toybox.Lang;

// Pure clock formatting so zero-padding is covered by unit tests.
module ClockText {
    function formatTime(hour as Number, minute as Number) as String {
        return hour.format("%02d") + ":" + minute.format("%02d");
    }
}
