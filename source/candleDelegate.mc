import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.System;

// Input for both of Candle's screens, parameterised by which it is.
//
// The measured event chain is ADR-0007 -- do not re-derive it. Why Back is
// swallowed everywhere and a held lower button is the only exit: ADR-0008,
// ADR-0009. Why the two screens are navigated by the upper button and by
// nothing on the glass: ADR-0036. Nothing here touches configureTouchEvents:
// ADR-0004.
class candleDelegate extends WatchUi.BehaviorDelegate {

    // Five steps a second: fast enough to cross a range in a reasonable hold,
    // slow enough to release on the value you wanted.
    const REPEAT_STEP_MILLIS = 200;

    private var _inputGate as MainInputGate;

    // The same list the view draws from, in the same order, which is what makes
    // a tap land on the row under the thumb without either file naming a
    // setting. ADR-0028
    private var _screen as Number;
    private var _rows as Array<Number>;

    // The glass every tap is decoded against. A delegate has no Dc to ask, so
    // it asks the device -- once -- and the view's dc.getWidth() is the same
    // number by the platform's own guarantee. Never a constant: the same
    // build runs on more than one size of glass. ADR-0045
    private var _width as Number;
    private var _height as Number;

    // onHold arms the repeat, onRelease disarms it -- the SDK guarantees an
    // onRelease only ever follows an onHold. Every other input handler disarms
    // it too, so a missed release can never leave a value running away. This is
    // the app's second of three timers. ADR-0006
    private var _repeatTimer as Timer.Timer? = null;
    private var _repeatHit as Number = Layout.HIT_NONE;

    function initialize(screen as Number) {
        BehaviorDelegate.initialize();
        _inputGate = new MainInputGate();
        _screen = screen;
        _rows = Rows.forScreen(screen);

        var settings = System.getDeviceSettings();
        _width = settings.screenWidth;
        _height = settings.screenHeight;
        traceMap();
    }

    // Arms the repeat only -- the immediate first step is onHold's job, so this
    // stays free of Storage writes and the tests can exercise the arming logic
    // without touching a stored setting. ADR-0030
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

    // At a range end the setter's clamp turns every tick into a no-op. ADR-0026
    function repeatCallback() as Void {
        adjustSetting(_repeatHit);
    }

    // One step immediately -- a hold should feel like a tap that keeps going,
    // not a pause then a burst -- and the repeat takes it from there.
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

    function onRelease(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (isRepeating()) {
            trace("onRelease -> repeat stopped");
        }
        stopRepeat();
        return true;
    }

    // A finger that starts dragging has stopped holding a control. DECLINED,
    // not consumed: drags feed the firmware's own gesture recognition, and this
    // exists only to disarm the repeat.
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        stopRepeat();
        return false;
    }

    // Purely an observer, and declined so it changes nothing. The trace is not
    // decoration: tests/input-behaviour.ps1 asserts on it, and for a left swipe
    // it is the only event the gesture raises at all. ADR-0007
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        trace("onSwipe " + (swipeEvent.getDirection() as Number));
        return false;
    }

    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        stopRepeat();
        _inputGate.press(keyEvent.getKey());
        // Declined: only a marker, the behaviour handlers do the work.
        return false;
    }

    function onKeyReleased(keyEvent as WatchUi.KeyEvent) as Boolean {
        _inputGate.release(keyEvent.getKey());
        return false;
    }

    // The upper button opens the settings screen and closes it again -- the
    // same press either way, so a screen opened by accident is undone by the
    // press that follows. Held, the button opens the watch's controls menu,
    // which never reaches the app; a hold and a press do not collide. ADR-0004
    //
    // **This is the ONLY way between the screens.** There is no drawn control
    // and no gesture: Back is swallowed on both, and the `BACK` button that
    // used to sit in the settings screen's bottom band was retired once it was
    // noticed that this press already did its job in both directions. ADR-0036
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

        // **Declining is what lets the later coordinate-bearing onTap run.**
        // Returning true suppresses it on this device, and onSelect has no
        // coordinates to edit a control with. ADR-0007
        trace("onSelect from tap -> awaiting coordinates");
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        stopRepeat();

        // A hold arrives typed CLICK_TYPE_HOLD and is onHold's job; letting it
        // fall through here would double-step.
        if (clickEvent.getType() != WatchUi.CLICK_TYPE_TAP) {
            trace("onTap non-tap click -> ignored");
            return true;
        }

        // Every tap is a row tap now, on both screens. The band below the rows
        // held a BACK button until ADR-0036 retired it; the row map returned
        // HIT_NONE down there then and still does, so a tap that lands in it is
        // ignored rather than special-cased.
        adjustSetting(hitAt(clickEvent));
        return true;
    }

    // **BACK NEVER DOES ANYTHING, ON EITHER SCREEN.** ADR-0009, ADR-0036
    //
    // One path, no screen branch. The two screens used to answer a swallowed
    // Back differently because the settings screen's bottom band was a BACK
    // button and a hint would have covered the control it described. The band
    // is empty since ADR-0036, and the gesture the hint names -- a held lower
    // button -- works from both screens, so the same answer is the right one in
    // both places.
    function onBack() as Boolean {
        stopRepeat();
        trace("onBack -> swallowed, hold to exit");
        getApp().armExitHint();
        return true;
    }

    // A HELD lower button, the one gesture the firmware has never been caught
    // forging. One handler for both screens. ADR-0009
    function onMenu() as Boolean {
        stopRepeat();

        // A synthesized KEY_ESC may well be sitting in the latch; nothing reads
        // it for Back any more, but leaving a stale key on the way out is
        // untidy and this is the last chance.
        _inputGate.clear();
        trace("onMenu -> app exits");

        // Last statement, and deliberately with no return after it: System.exit
        // does not come back, and the compiler knows -- a trailing `return true`
        // here builds with "Statement is not reachable" at -w.
        System.exit();
    }

    // Neither screen has a page above or below it, so vertical swipes are
    // swallowed rather than allowed to page away mid-session.
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

    // Maps against the device's reported screen while the view draws with
    // dc.getWidth(); a test pins that the glass is square, which is the
    // assumption the chord maths and this call share. ADR-0045
    private function hitAt(clickEvent as WatchUi.ClickEvent) as Number {
        var coordinates = clickEvent.getCoordinates();
        return Layout.editorHitAt(
            coordinates[0], coordinates[1], _width, _height, _rows.size());
    }

    // The one place a position on the glass meets the setting under it -- by
    // index into the screen's own row list, so this file names no setting at
    // all. ADR-0028
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

    // Dropped from release builds at compile time, so this costs nothing on the
    // watch -- but tests/input-behaviour.ps1 asserts on these lines. ADR-0031
    (:debug)
    private function trace(msg as String) as Void {
        System.println("[input] " + msg);
    }

    (:release)
    private function trace(msg as String) as Void {
    }

    // The geometry this screen's taps are decoded against, printed once when
    // the screen is created, so tests/input-behaviour.ps1 can aim at the
    // controls on whatever glass the simulator is showing instead of carrying
    // coordinates measured on one watch. The script parses this line; its
    // shape is part of the contract. Debug only, like every trace. ADR-0045
    (:debug)
    private function traceMap() as Void {
        var count = _rows.size();
        var rows = "";
        for (var i = 0; i < count; i += 1) {
            if (i > 0) {
                rows += ",";
            }
            rows += Layout.editorRowCenter(i, count, _height).toString();
        }
        var below = Layout.editorRowsTop(count, _height) + (count * Layout.editorRowHeight(_height));
        trace("map screen " + _screen + " width " + _width + " height " + _height +
            " rows " + rows + " edge " + Layout.controlHitEdge(_width) + " below " + below);
    }

    (:release)
    private function traceMap() as Void {
    }
}
