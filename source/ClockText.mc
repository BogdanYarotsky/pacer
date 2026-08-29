import Toybox.Lang;

// Clock rendering, 12- and 24-hour. Pure, so every minute of the day is swept
// by a test rather than sampled. ADR-0030
module ClockText {

    // ONE LETTER, not "AM"/"PM", and that is forced by the band rather than
    // chosen. The clock sits in the top slot at FONT_MEDIUM, which is the
    // narrowest place this app draws text: the budget there is 166 px and
    // "12:48 PM" is 189, "12:48pm" 175, "10:08 PM" 189. Every full form clips.
    // "12:48a" is 135. ADR-0042
    //
    // Lower case on purpose. The screen's other words are upper-case captions
    // (EVERY, POWER, BUZZ, BPM) and a capital P beside the clock would read as
    // one of them rather than as part of the time.
    const SUFFIX_AM = "a";
    const SUFFIX_PM = "p";

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
