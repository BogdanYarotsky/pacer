import Toybox.Lang;
import Toybox.WatchUi;

// Separates behavior events from physical-button events.
//
// **READ THIS BEFORE TRUSTING IT.** The premise is that touch gestures never
// call press(), so consume() returns false for them. That is true in the
// simulator and it is TRUE FOR KEY_ENTER on the watch -- a tap raises onSelect
// without a key, which is why the upper button can still be told apart from a
// tap and why the settings screen opens when it should.
//
// It is FALSE FOR KEY_ESC on real hardware. The firmware synthesizes a genuine
// onKeyPressed(KEY_ESC) for a right swipe: six breadcrumbs from a wrist on
// 2026-08-25, every one ending P5>B!, from swipes with no button press. So the
// gate cannot classify Back, and onBack no longer asks it to -- Back is
// swallowed on the main screen and the only exit is a held lower button.
//
// What is left here has one job: onSelect, where it still works. Do not give it
// KEY_ESC work back without new evidence from a wrist.
class MainInputGate {
    private var _latchedKey as WatchUi.Key? = null;

    function press(key as WatchUi.Key) as Void {
        _latchedKey = key;
    }

    function release(key as WatchUi.Key) as Void {
        if (_latchedKey == key) {
            _latchedKey = null;
        }
    }

    // A press classifies at most one behavior, whether it matches or not.
    function consume(key as WatchUi.Key) as Boolean {
        var matched = _latchedKey == key;
        _latchedKey = null;
        return matched;
    }

    function clear() as Void {
        _latchedKey = null;
    }
}
