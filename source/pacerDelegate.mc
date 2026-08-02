import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// Main-screen input, v0.15.
//
// THE PROBLEM: a behaviour event on its own cannot tell a physical button from
// a touch. Measured on a vivoactive 5 by driving real input into the simulator
// (tools/input.ps1); this is the observed event chain, not inference:
//
//   tap          -> onSelect, then onTap        (onSelect fires FIRST)
//   press enter  -> onKeyPressed(4), onSelect, onKey(4), onKeyReleased(4)
//   press esc    -> onKeyPressed(5), onBack, onKeyReleased(5)
//   hold  menu   -> onKeyPressed(5), onMenu, onKey(7), onKeyReleased(5)
//   swipe right  -> onBack           <-- no onSwipe event at all
//   swipe left   -> nothing
//   swipe up     -> onNextPage, onSwipe(0)
//   swipe down   -> onPreviousPage, onSwipe(2)
//
// Two consequences that earlier versions of this file got wrong:
//
//   * Consuming onTap CANNOT suppress a tap, because onSelect is dispatched
//     before onTap ever runs.
//   * A right-swipe never raises onSwipe, so filtering SWIPE_RIGHT there is
//     dead code. The swipe arrives only as onBack -- the same event as the
//     lower physical button.
//
// THE FIX: onKeyPressed fires for physical buttons and never for gestures, and
// always immediately before the behaviour event. Latching the pressed key and
// consuming it inside the behaviour handler tells the two apart reliably.
//
//   onSelect  with a fresh KEY_ENTER latch -> upper button -> open settings
//   onSelect  with no latch                -> a tap        -> swallow
//   onBack    with a fresh KEY_ESC latch   -> lower button -> let the app exit
//   onBack    with no latch                -> right-swipe  -> swallow
class pacerDelegate extends WatchUi.BehaviorDelegate {
    private var _inputGate as MainInputGate = new MainInputGate();

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        _inputGate.press(keyEvent.getKey());
        // Declined: this is only a marker, the behaviour handlers do the work.
        return false;
    }

    // Clear a press that produced no behaviour. A stale KEY_ESC must never make
    // a later right-swipe look like the physical lower button.
    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        _inputGate.release(keyEvent.getKey());
        return false;
    }

    function onSelect() as Boolean {
        if (_inputGate.consume(WatchUi.KEY_ENTER)) {
            trace("onSelect from upper button -> settings");
            showPacerSettings();
        } else {
            trace("onSelect from tap -> swallowed");
        }
        // Always consumed: a tap must never reach the system default.
        return true;
    }

    function onBack() as Boolean {
        if (_inputGate.consume(WatchUi.KEY_ESC)) {
            trace("onBack from lower button -> declined, app exits");
            return false;
        }
        trace("onBack from swipe -> swallowed");
        return true;
    }

    // Holding the lower button raises the menu behaviour on this device.
    function onMenu() as Boolean {
        trace("onMenu -> settings");
        _inputGate.clear();   // the press that produced this must not linger
        showPacerSettings();
        return true;
    }

    // Vertical swipes are page behaviours here. Pacer has a single screen, so
    // they are swallowed rather than allowed to page away mid-session.
    function onNextPage() as Boolean {
        trace("onNextPage -> swallowed");
        return true;
    }

    function onPreviousPage() as Boolean {
        trace("onPreviousPage -> swallowed");
        return true;
    }

    // Input tracing. (:debug) blocks are dropped from release builds at compile
    // time, so this costs nothing on the watch. tests/input-behaviour.ps1 drives
    // real input into the simulator and asserts on these lines.
    (:debug)
    private function trace(msg as String) as Void {
        System.println("[input] " + msg);
    }

    (:release)
    private function trace(msg as String) as Void {
    }
}
