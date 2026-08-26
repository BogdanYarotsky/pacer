import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.System;

// Input for both of Candle's screens.
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
// onKeyPressed distinguishes both physical buttons from touch behavior, and
// that distinction now carries two jobs rather than one. On the main screen a
// right-swipe and the lower button arrive as the same onBack and only one of
// them may close the app -- and the upper button, which reaches onSelect
// alongside every tap on the glass, is the one that opens the settings screen.
//
// One class for both screens, parameterised by which it is. What differs is
// only what the two buttons mean there: on MAIN the upper button pushes the
// settings screen and Back is swallowed; on SETTINGS either of them pops back,
// and a stray swipe pops it too, because landing on the main screen costs a
// wearer nothing.
//
// Nothing exits except a HELD lower button, on either screen. Back cannot be
// trusted with it -- see onBack.
//
// Palm safety is the watch's own Lock Screen, not Candle's job. Nothing here
// touches WatchUi.configureTouchEvents -- see AGENTS.md for why that matters.
class candleDelegate extends WatchUi.BehaviorDelegate {

    // One repeat step every 200 ms while a control is held -- five steps a
    // second, fast enough that the 299-tap EVERY range crosses in a minute
    // and slow enough to release on the value you wanted.
    const REPEAT_STEP_MILLIS = 200;

    private var _inputGate as MainInputGate;

    // Which screen this delegate serves, and the rows on it. The list is the
    // same one candleView draws from, in the same order, which is what makes a
    // tap land on the row under the thumb without either file naming a setting.
    private var _screen as Number;
    private var _rows as Array<Number>;

    // The hold-to-repeat machinery. onHold arms it with the hit under the
    // finger, onRelease disarms it -- the SDK guarantees the pairing: an
    // onRelease is only ever sent after an onHold. Every other input handler
    // disarms it too, so a missed release can never leave a value running
    // away on its own. This is the app's second and last Timer; the device
    // allows three.
    private var _repeatTimer as Timer.Timer? = null;
    private var _repeatHit as Number = Layout.HIT_NONE;

    function initialize(screen as Number) {
        BehaviorDelegate.initialize();
        _inputGate = new MainInputGate();
        _screen = screen;
        _rows = Rows.forScreen(screen);
    }

    // Arm the repeat only -- the immediate first step is onHold's job, so
    // these stay free of Storage writes and the unit tests can exercise the
    // arming logic without touching a stored setting.
    function startRepeat(hit as Number) as Void {
        stopRepeat();
        var timer = new Timer.Timer();
        timer.start(method(:repeatCallback), REPEAT_STEP_MILLIS, true);
        _repeatTimer = timer;
        _repeatHit = hit;
    }

    function stopRepeat() as Void {
        var timer = _repeatTimer;
        if (timer != null) {
            timer.stop();
            _repeatTimer = null;
        }
        _repeatHit = Layout.HIT_NONE;
    }

    function isRepeating() as Boolean {
        return _repeatTimer != null;
    }

    // At a range end the setter's clamp turns every tick into a no-op, so a
    // hold parked on an endpoint costs five empty calls a second and changes
    // nothing -- the timer still stops at release like any other.
    function repeatCallback() as Void {
        adjustSetting(_repeatHit);
    }

    // A touch held on a control: one step immediately -- the hold should feel
    // like a tap that keeps going, not a pause then a burst -- and the repeat
    // timer takes it from there until the finger lifts.
    function onHold(clickEvent as WatchUi.ClickEvent) as Boolean {
        var hit = hitAt(clickEvent);
        if (hit == Layout.HIT_NONE) {
            trace("onHold outside controls -> ignored");
            return true;
        }

        trace("onHold -> step and repeat");
        adjustSetting(hit);
        startRepeat(hit);
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
    //
    // It used to log the drag for the exit breadcrumb as well, on the theory
    // that a drag is the one witness to "a finger was on the glass" that the
    // firmware does not synthesize. The wrist settled that question -- touch
    // evidence preceded the forged key in only two exits out of six -- and
    // disarming the repeat is all this handler was ever needed for.
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        stopRepeat();
        return false;
    }

    // Purely an observer, and declined so it changes nothing.
    //
    // The measured chain says a right swipe never raises onSwipe on this device
    // -- but that was measured in the SIMULATOR, and the simulator has since
    // been shown to lie about this exact gesture: it raises no key event for a
    // right swipe where the watch raises a real KEY_ESC. So the question is
    // worth re-asking on hardware, and this is what asks it.
    //
    // Up and down swipes already reach onNextPage/onPreviousPage, which consume
    // them; this runs afterwards either way and only traces. The trace is not
    // decoration: tests/input-behaviour.ps1 asserts "onSwipe 3" for a left
    // swipe, which is the only event that gesture raises at all.
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        trace("onSwipe " + (swipeEvent.getDirection() as Number));
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

    // The upper button opens the settings screen, and closes it again.
    //
    // It had no job at all between losing Candle's touch lock and gaining this
    // one. What it opens is the interval -- the one setting that is measured
    // once and then left alone -- and moving it off the main screen is what
    // bought the two rows that remain their size. Held, the button still opens
    // the watch's controls menu, which never reaches the app and is where Lock
    // Screen lives; that is a hold, not a press, and the two do not collide.
    //
    // The same button closes it, so a press that opened the screen by accident
    // is undone by the press that follows rather than by finding another
    // gesture. Back does it too.
    function onSelect() as Boolean {
        stopRepeat();
        if (_inputGate.consume(WatchUi.KEY_ENTER)) {
            if (_screen == Rows.SCREEN_MAIN) {
                trace("upper button -> settings");
                WatchUi.pushView(
                    new candleView(Rows.SCREEN_SETTINGS),
                    new candleDelegate(Rows.SCREEN_SETTINGS),
                    WatchUi.SLIDE_LEFT);
            } else {
                trace("upper button -> settings closed");
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
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

        // The BACK button, before the rows. It is asked first because it owns
        // the band BELOW the row block and the row map returns HIT_NONE there
        // anyway -- the order is about reading, not about resolving a clash.
        //
        // Settings only. The main screen's bottom band holds the battery, which
        // nothing taps, and its way out is a held button rather than a target.
        if (_screen != Rows.SCREEN_MAIN && isBackTap(clickEvent)) {
            trace("tap BACK -> settings closed");
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }

        adjustSetting(hitAt(clickEvent));
        return true;
    }

    // **BACK NEVER EXITS.** It pops the settings screen and it does nothing at
    // all on the main screen, and that is the fix for the phantom swipe-exit.
    //
    // The gate is not consulted here any more, and deleting that check is the
    // whole change. It asked "was a KEY_ESC latched?", which was a sound
    // question right up until the wrist answered it: the firmware synthesizes a
    // real onKeyPressed(KEY_ESC) for a right swipe. Six breadcrumbs on
    // 2026-08-25, every one ending P5>B!, and touch evidence arrived ahead of
    // the key in only two of the six -- so there is no companion event to gate
    // on either. onBack simply cannot tell a thumb from a sleeve on this
    // hardware, and code that acts on an answer it cannot have is the bug.
    //
    // What replaces it is onMenu, below: a HELD lower button, which is the one
    // gesture in this whole investigation the firmware has never been caught
    // forging.
    //
    // The main screen still arms the hint, because a Back that changes nothing
    // on screen reads as a frozen app -- and because it names the gesture that
    // does work. The settings screen needs no hint: Back does something visible
    // there, and popping costs a wearer nothing since the cue timer lives in
    // the app and never stopped.
    // **BACK NEVER DOES ANYTHING, ON EITHER SCREEN**, and the settings screen
    // joined the main screen in that on 2026-08-25.
    //
    // It popped the settings screen until then, on the reasoning that landing
    // on the main screen costs a wearer nothing. That reasoning was about
    // deliberate Backs. The forged ones are the problem: a right swipe raises
    // the same synthesized KEY_ESC here as anywhere, so a sleeve crossing the
    // glass closed the screen out from under a value being adjusted. Losing
    // your place mid-adjustment costs more than the pop was ever worth.
    //
    // What replaces it is the BACK button along the bottom -- see
    // Display.backLabel. The main screen arms a hint here instead, because it
    // has no visible control to point at and a Back that changes nothing on
    // screen reads as a frozen app. The settings screen needs no hint: the
    // thing to press is already drawn, permanently, and a hint would have to
    // cover it to say so.
    function onBack() as Boolean {
        stopRepeat();

        if (_screen != Rows.SCREEN_MAIN) {
            trace("onBack on settings -> swallowed, tap BACK");
            return true;
        }

        trace("onBack -> swallowed, hold to exit");
        getApp().armExitHint();
        return true;
    }

    // Holding the lower button exits the app, from either screen.
    //
    // System.exit ends the app "cleanly from any point within an app", so this
    // needs no view-stack unwinding and one handler serves both screens --
    // restricting the exit to the main screen would cost a branch, not save
    // one. One rule, everywhere: hold the lower button to quit.
    //
    // A hold cannot be produced by a swipe. The measured chain is
    // onKeyPressed(5), onMenu, onKey(7), onKeyReleased(5) -- and onMenu was
    // confirmed on the wrist on 2026-08-25, reliably, by holding the button and
    // reading "M" back out of the breadcrumb. That is what makes it safe to
    // hang the only exit on it.
    //
    // The latch is cleared because a synthesized KEY_ESC may well be sitting in
    // it; nothing reads it for Back any more, but leaving a stale key behind on
    // the way out is untidy and this is the last chance.
    function onMenu() as Boolean {
        stopRepeat();
        _inputGate.clear();
        trace("onMenu -> app exits");

        // Last statement, and deliberately with no return after it: System.exit
        // does not come back, and the compiler knows -- a trailing `return true`
        // here builds with "Statement is not reachable" at -w.
        System.exit();
    }

    // Vertical swipes are page behaviours here. Neither screen has a page above
    // or below it, so they are swallowed rather than allowed to page away
    // mid-session.
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

    // Where a click landed, as a row position and a direction on THIS screen.
    // Layout knows how many rows are under the finger and nothing about what
    // they are; that is the point of the encoding.
    // Whether a click landed in the settings screen's BACK band. Same width and
    // height Layout.editorHitAt is given, for the same reason: the delegate maps
    // taps against Layout.DISPLAY_WIDTH while the view draws with dc.getWidth(),
    // and layoutDisplayWidthMatchesTheDevice is what keeps those two the same
    // number.
    private function isBackTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        return Layout.isBackTap(coordinates[1], Layout.DISPLAY_WIDTH, _rows.size());
    }

    private function hitAt(clickEvent as WatchUi.ClickEvent) as Number {
        var coordinates = clickEvent.getCoordinates();
        return Layout.editorHitAt(
            coordinates[0], coordinates[1],
            Layout.DISPLAY_WIDTH, Layout.DISPLAY_WIDTH, _rows.size());
    }

    // The one place a position on the glass meets the setting under it -- and
    // it does that by index into the screen's own row list, so this file names
    // no setting at all. The six-armed if-chain over ACTION_ constants that
    // used to live here was the second copy of the row order; candleApp.stepRow
    // is the first and only one now.
    //
    // Traces name the row through its caption, so tests/input-behaviour.ps1
    // asserts what a thumb on that row actually edited.
    private function adjustSetting(hit as Number) as Void {
        if (hit == Layout.HIT_NONE) {
            trace("tap outside controls -> ignored");
            return;
        }

        var row = _rows[Layout.hitRow(hit)] as Number;
        var increase = Layout.hitIsIncrease(hit);
        getApp().stepRow(row, increase);
        trace("tap " + Display.rowLabel(row) + (increase ? " +" : " -"));
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
