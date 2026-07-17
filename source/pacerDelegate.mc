import Toybox.Lang;
import Toybox.WatchUi;

class pacerDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Select combines the upper Action button and screen taps on touch devices.
    // Let it fall through so onKey can accept only the physical KEY_ENTER event.
    function onSelect() as Boolean {
        return false;
    }

    // Garmin maps both a right swipe and the lower Back button to this behavior
    // on the vivoactive 5. Consume both so a swipe can never close the app. The
    // settings menu provides an explicit, unambiguous Exit Pacer action.
    function onBack() as Boolean {
        return true;
    }

    // Some firmware reports the same right swipe as a raw KEY_ESC as well as
    // the Back behavior, so consume the raw forms too.
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            showPacerSettings();
            return true;
        }

        return key == WatchUi.KEY_ESC;
    }

    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        return keyEvent.getKey() == WatchUi.KEY_ESC;
    }

    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        return keyEvent.getKey() == WatchUi.KEY_ESC;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        return swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT;
    }
}
