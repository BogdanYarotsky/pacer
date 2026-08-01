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

    // Both the lower Back button and a right swipe raise this behavior. Decline
    // it so the event splits into its raw form: a physical press arrives at
    // onKey as KEY_ESC, while a swipe arrives at onSwipe. That split is the only
    // place the two can be told apart.
    function onBack() as Boolean {
        return false;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            showPacerSettings();
            return true;
        }

        // Decline KEY_ESC so the physical Back button exits the app.
        return false;
    }

    // Swallow the right swipe so a stray touch cannot end a session.
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        return swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT;
    }
}
