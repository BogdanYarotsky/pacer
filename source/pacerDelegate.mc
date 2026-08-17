import Toybox.Lang;
import Toybox.Timer;
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
//   touch hold   -> onHold after the threshold, onRelease at lift
//                   -- and neither onSelect nor onTap, so the tap path and
//                   the hold path are disjoint by measurement, not hope
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

    // One repeat step every 200 ms while a control is held -- five steps a
    // second, fast enough that the 299-tap EVERY range crosses in a minute
    // and slow enough to release on the value you wanted.
    const REPEAT_STEP_MILLIS = 200;

    private var _inputGate as MainInputGate;

    // The hold-to-repeat machinery. onHold arms it with the action under the
    // finger, onRelease disarms it -- the SDK guarantees the pairing: an
    // onRelease is only ever sent after an onHold. Every other input handler
    // disarms it too, so a missed release can never leave a value running
    // away on its own. This is the app's second and last Timer; the device
    // allows three.
    private var _repeatTimer as Timer.Timer? = null;
    private var _repeatAction as Number = Layout.ACTION_NONE;

    function initialize() {
        BehaviorDelegate.initialize();
        _inputGate = new MainInputGate();
    }

    // Arm the repeat only -- the immediate first step is onHold's job, so
    // these stay free of Storage writes and the unit tests can exercise the
    // arming logic without touching a stored setting.
    function startRepeat(action as Number) as Void {
        stopRepeat();
        var timer = new Timer.Timer();
        timer.start(method(:repeatCallback), REPEAT_STEP_MILLIS, true);
        _repeatTimer = timer;
        _repeatAction = action;
    }

    function stopRepeat() as Void {
        var timer = _repeatTimer;
        if (timer != null) {
            timer.stop();
            _repeatTimer = null;
        }
        _repeatAction = Layout.ACTION_NONE;
    }

    function isRepeating() as Boolean {
        return _repeatTimer != null;
    }

    // At a range end the setter's clamp turns every tick into a no-op, so a
    // hold parked on an endpoint costs five empty calls a second and changes
    // nothing -- the timer still stops at release like any other.
    function repeatCallback() as Void {
        adjustSetting(_repeatAction);
    }

    // A touch held on a control: one step immediately -- the hold should feel
    // like a tap that keeps going, not a pause then a burst -- and the repeat
    // timer takes it from there until the finger lifts.
    function onHold(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var action = Layout.editorActionAt(
            coordinates[0], coordinates[1], Layout.DISPLAY_WIDTH);
        if (action == Layout.ACTION_NONE) {
            trace("onHold outside controls -> ignored");
            return true;
        }

        trace("onHold -> step and repeat");
        adjustSetting(action);
        startRepeat(action);
        return true;
    }

    // Only ever sent after an onHold, once the hold is released.
    function onRelease(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (isRepeating()) {
            trace("onRelease -> repeat stopped");
        }
        stopRepeat();
        return true;
    }

    // A finger that starts dragging has stopped holding a control. Declined
    // rather than consumed: drags feed the firmware's own gesture recognition,
    // and this handler exists only to disarm the repeat, not to eat swipes.
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        stopRepeat();
        return false;
    }

    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        stopRepeat();
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
        stopRepeat();
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
        stopRepeat();
        // Only a plain tap steps here. A hold arrives typed CLICK_TYPE_HOLD
        // and is onHold's job; letting it fall through would double-step.
        if (clickEvent.getType() != WatchUi.CLICK_TYPE_TAP) {
            trace("onTap non-tap click -> ignored");
            return true;
        }

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
        stopRepeat();
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
        stopRepeat();
        trace("onMenu -> swallowed");
        _inputGate.clear();
        return true;
    }

    // Vertical swipes are page behaviours here. Pacer has a single screen, so
    // they are swallowed rather than allowed to page away mid-session.
    function onNextPage() as Boolean {
        stopRepeat();
        trace("onNextPage -> swallowed");
        return true;
    }

    function onPreviousPage() as Boolean {
        stopRepeat();
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
