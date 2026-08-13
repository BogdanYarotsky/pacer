import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Timer;

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
    const EXIT_WINDOW_MS = 4000;
    const RESTORE_DELAY_MS = 150;

    private var _inputGate as MainInputGate = new MainInputGate();
    private var _exitArmed as Boolean = false;
    private var _exitRequested as Boolean = false;
    private var _touchRestored as Boolean = false;
    private var _exitWindowTimer as Timer.Timer? = null;
    private var _restoreTimer as Timer.Timer? = null;

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
            cancelExitConfirmation();
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

        cancelExitConfirmation();
        var coordinates = clickEvent.getCoordinates();
        var action = Layout.editorActionAt(
            coordinates[0], coordinates[1], Layout.DISPLAY_WIDTH);
        adjustSetting(action);
        return true;
    }

    function onBack() as Boolean {
        if (_inputGate.consume(WatchUi.KEY_ESC)) {
            if (!_exitArmed) {
                armExitConfirmation();
                trace("onBack from lower button -> exit armed");
                return true;
            }

            _exitRequested = true;
            if (_touchRestored) {
                clearExitState();
                trace("onBack from lower button -> confirmed, app exits");
                return false;
            }

            // A very fast second press can beat the asynchronous restoration,
            // or the first attempt may have failed. Retry without blocking the
            // input handler; the callback exits if restoration succeeds.
            scheduleTouchRestore();
            trace("onBack from lower button -> confirmed, cleanup pending");
            return true;
        }
        trace("onBack from swipe -> swallowed");
        return true;
    }

    // There is no second screen. Holding the lower button is intentionally a
    // no-op and its key latch must not leak into a later Back gesture.
    function onMenu() as Boolean {
        cancelExitConfirmation();
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

    // First Back returns immediately so the prompt can render. Cleanup starts
    // on the next UI turn rather than making the press appear unresponsive.
    private function armExitConfirmation() as Void {
        stopExitTimers();
        _exitArmed = true;
        _exitRequested = false;
        _touchRestored = false;
        getApp().setExitPromptVisible(true);

        var windowTimer = new Timer.Timer();
        windowTimer.start(method(:expireExitConfirmation), EXIT_WINDOW_MS, false);
        _exitWindowTimer = windowTimer;
        scheduleTouchRestore();
    }

    private function scheduleTouchRestore() as Void {
        var existing = _restoreTimer;
        if (existing != null) {
            existing.stop();
        }

        var restoreTimer = new Timer.Timer();
        restoreTimer.start(method(:restoreTouchForExit), RESTORE_DELAY_MS, false);
        _restoreTimer = restoreTimer;
    }

    function restoreTouchForExit() as Void {
        _restoreTimer = null;
        if (!_exitArmed) {
            return;
        }

        _touchRestored = TouchControl.setEnabled(true);
        if (!_touchRestored) {
            trace("exit cleanup -> touch restore failed");
            return;
        }

        trace("exit cleanup -> touch restored");
        if (_exitRequested) {
            clearExitState();
            trace("exit cleanup -> confirmed, app exits");
            System.exit();
        }
    }

    function expireExitConfirmation() as Void {
        _exitWindowTimer = null;
        if (!_exitArmed) {
            return;
        }

        clearExitState();
        trace("exit window expired -> editor restored");
        getApp().applyTouchLock();
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

    private function cancelExitConfirmation() as Void {
        if (_exitArmed) {
            clearExitState();
            trace("exit confirmation cancelled");
        }
    }

    private function clearExitState() as Void {
        stopExitTimers();
        _exitArmed = false;
        _exitRequested = false;
        _touchRestored = false;
        getApp().setExitPromptVisible(false);
    }

    private function stopExitTimers() as Void {
        var windowTimer = _exitWindowTimer;
        if (windowTimer != null) {
            windowTimer.stop();
            _exitWindowTimer = null;
        }

        var restoreTimer = _restoreTimer;
        if (restoreTimer != null) {
            restoreTimer.stop();
            _restoreTimer = null;
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
