import Toybox.Lang;
import Toybox.WatchUi;

// Separates behavior events from physical-button events on the main screen.
// Touch gestures never call press(), so consume() returns false for them.
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
