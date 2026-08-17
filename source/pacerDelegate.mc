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
// onKeyPressed distinguishes both physical buttons from touch behavior, and that
// distinction is the only thing this class still needs to get right: a
// right-swipe and the lower button arrive as the same onBack, and only one of
// them may close the app.
//
// Palm safety is the watch's own Lock Screen, not Pacer's job. Nothing here
// touches WatchUi.configureTouchEvents -- see AGENTS.md for why that matters.
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

    // The upper button has no job left -- it used to toggle Pacer's own touch
    // lock. It is still consumed rather than declined, so a press cannot fall
    // through to anything else. Held, it opens the watch's controls menu, which
    // never reaches the app at all and is where the Lock Screen lives.
    function onSelect() as Boolean {
        if (_inputGate.consume(WatchUi.KEY_ENTER)) {
            trace("upper button -> no action");
            return true;
        }

        // Declining here is what lets the later coordinate-bearing onTap run:
        // returning true would suppress it on vivoactive 5, and onSelect has no
        // coordinates to edit a control with.
        trace("onSelect from tap -> awaiting coordinates");
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        adjustSetting(Layout.editorActionAt(
            coordinates[0], coordinates[1], Layout.DISPLAY_WIDTH));
        return true;
    }

    // Back exits. That is the whole rule.
    //
    // It used to be conditional, because Pacer disabled the watch-global touch
    // setting itself and must never have left it that way -- first a four-second
    // two-press confirmation with two timers, then a single check of its own lock
    // flag. The watch's built-in Lock Screen now owns palm safety, so Pacer
    // disables nothing and has nothing to restore before leaving.
    //
    // The swipe check stays, and is now the only conditional in this file. A
    // right-swipe arrives as the same onBack as the lower button, so without the
    // gate a stray swipe would close the app mid-session.
    function onBack() as Boolean {
        if (!_inputGate.consume(WatchUi.KEY_ESC)) {
            trace("onBack from swipe -> swallowed");
            return true;
        }

        trace("onBack from lower button -> app exits");
        return false;
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

    // The one place a row's caption meets the setting under it: EVERY is the
    // cue interval, PULSE the vibration length, POWER the vibration strength.
    // Traces name the row, so tests/input-behaviour.ps1 asserts what a thumb on
    // that row actually edited.
    private function adjustSetting(action as Number) as Void {
        var app = getApp();

        if (action == Layout.ACTION_EVERY_DOWN) {
            app.setEveryHundredths(app.getEveryHundredths() - app.EVERY_STEP);
            trace("tap every -");
        } else if (action == Layout.ACTION_EVERY_UP) {
            app.setEveryHundredths(app.getEveryHundredths() + app.EVERY_STEP);
            trace("tap every +");
        } else if (action == Layout.ACTION_PULSE_DOWN) {
            app.setVibrationDuration(app.getVibrationDuration() - app.DURATION_STEP);
            trace("tap pulse -");
        } else if (action == Layout.ACTION_PULSE_UP) {
            app.setVibrationDuration(app.getVibrationDuration() + app.DURATION_STEP);
            trace("tap pulse +");
        } else if (action == Layout.ACTION_POWER_DOWN) {
            app.setVibrationStrength(PacerMath.strengthDown(app.getVibrationStrength()));
            trace("tap power -");
        } else if (action == Layout.ACTION_POWER_UP) {
            app.setVibrationStrength(PacerMath.strengthUp(app.getVibrationStrength()));
            trace("tap power +");
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
