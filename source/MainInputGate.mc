import Toybox.Lang;
import Toybox.WatchUi;

// Separates behavior events from physical-button events.
//
// **Its premise is FALSE for KEY_ESC on real hardware and TRUE for KEY_ENTER.**
// The firmware forges a key event for a right swipe, so this cannot classify
// Back and onBack no longer asks it to. What is left has one job: onSelect,
// where it still works. Do not give it KEY_ESC work back without new evidence
// from a wrist. ADR-0008
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

    // A press classifies at most one behavior, whether it matches or not: a
    // stale KEY_ESC must never make a later right-swipe look like the button.
    function consume(key as WatchUi.Key) as Boolean {
        var matched = _latchedKey == key;
        _latchedKey = null;
        return matched;
    }

    function clear() as Void {
        _latchedKey = null;
    }
}
