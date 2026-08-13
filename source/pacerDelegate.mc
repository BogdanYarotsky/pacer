import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// Input for Pacer's only screen.
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
// onKeyPressed distinguishes both physical buttons from touch behavior. Touch
// starts enabled so onTap can edit the three rows. The upper button toggles the
// global palm-safe lock; it remains available when that lock suppresses touch.
class pacerDelegate extends WatchUi.BehaviorDelegate {

    private var _inputGate as MainInputGate;

    function initialize() {
        BehaviorDelegate.initialize();
        _inputGate = new MainInputGate();
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
            var app = getApp();
            var lock = !app.isTouchLocked();
            if (app.setTouchLocked(lock)) {
                trace(lock ? "upper button -> touch locked" : "upper button -> touch unlocked");
            } else {
                trace(lock ? "upper button -> lock failed" : "upper button -> unlock failed");
            }
            return true;
        }

        // Returning true here suppresses the later coordinate-bearing onTap
        // callback on vivoactive 5. Defer an unlocked tap so onTap can edit the
        // selected control, but consume the behavior immediately while locked.
        if (getApp().isTouchLocked()) {
            trace("onSelect while locked -> swallowed");
            return true;
        }

        trace("onSelect from tap -> awaiting coordinates");
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var app = getApp();
        if (app.isTouchLocked()) {
            trace("onTap while locked -> swallowed");
            return true;
        }

        var coordinates = clickEvent.getCoordinates();
        adjustSetting(Layout.editorActionAt(
            coordinates[0], coordinates[1], Layout.DISPLAY_WIDTH));
        return true;
    }

    // Back exits -- but never while the watch-global touch setting is still
    // disabled, because that setting can outlive Pacer and leave the whole watch
    // untouchable until it is rebooted.
    //
    // The lock flag already answers that question exactly. pacerApp records a
    // lock only after TouchControl confirms the setting really changed, and
    // nothing else in the app ever disables touch, so "unlocked" and "safe to
    // exit" are the same condition. That is why there is no confirmation window,
    // no restore timer and no exit state here: an earlier version tracked armed
    // / requested / restored across two timers to derive a fact the lock flag
    // was already holding.
    //
    // While locked, Back unlocks and stays put. A session is locked anyway, so
    // that hands back the two-press exit the old confirmation window provided,
    // out of the state a session is already in. If the unlock is rejected, Pacer
    // stays open and stays locked -- the safe failure, and the same one the old
    // four-second window reached by a much longer road.
    function onBack() as Boolean {
        if (!_inputGate.consume(WatchUi.KEY_ESC)) {
            trace("onBack from swipe -> swallowed");
            return true;
        }

        var app = getApp();
        if (!app.isTouchLocked()) {
            trace("onBack from lower button -> touch already on, app exits");
            return false;
        }

        if (app.setTouchLocked(false)) {
            trace("onBack from lower button -> touch unlocked, press again to exit");
        } else {
            trace("onBack from lower button -> unlock failed, staying open");
        }
        return true;
    }

    // There is no second screen. Holding the lower button is intentionally a
    // no-op and its key latch must not leak into a later Back gesture.
    function onMenu() as Boolean {
        trace("onMenu -> swallowed");
        _inputGate.clear();
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

    private function adjustSetting(action as Number) as Void {
        var app = getApp();

        if (action == Layout.ACTION_PACE_DOWN) {
            app.setPaceHundredths(app.getPaceHundredths() - app.PACE_STEP);
            trace("tap pace -");
        } else if (action == Layout.ACTION_PACE_UP) {
            app.setPaceHundredths(app.getPaceHundredths() + app.PACE_STEP);
            trace("tap pace +");
        } else if (action == Layout.ACTION_STRENGTH_DOWN) {
            app.setVibrationStrength(app.getVibrationStrength() - app.STRENGTH_STEP);
            trace("tap strength -");
        } else if (action == Layout.ACTION_STRENGTH_UP) {
            app.setVibrationStrength(app.getVibrationStrength() + app.STRENGTH_STEP);
            trace("tap strength +");
        } else if (action == Layout.ACTION_DURATION_DOWN) {
            app.setVibrationDuration(app.getVibrationDuration() - app.DURATION_STEP);
            trace("tap length -");
        } else if (action == Layout.ACTION_DURATION_UP) {
            app.setVibrationDuration(app.getVibrationDuration() + app.DURATION_STEP);
            trace("tap length +");
        } else {
            trace("tap outside controls -> ignored");
        }
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
