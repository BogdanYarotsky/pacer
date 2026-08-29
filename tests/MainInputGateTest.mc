import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// A real hit code for a control on the main screen, built through the same map
// candleDelegate uses rather than spelled out. The encoding is Layout's
// business; what these tests need is a value the repeat machinery would
// actually be armed with.
function mainScreenHit(index as Number, increase as Boolean) as Number {
    var count = Rows.forScreen(Rows.SCREEN_MAIN).size();
    var w = Layout.DISPLAY_WIDTH;
    var x = increase ? w - 50 : 50;
    return Layout.editorHitAt(x, Layout.editorRowCenter(index, count, w), w, w, count);
}

// This is the right-swipe case without simulator or mouse synthesis: no
// physical key was pressed, so Back must not be classified as the lower button.
(:test)
function mainInputGateRejectsBackWithoutKey(logger as Test.Logger) as Boolean {
    var gate = new MainInputGate();
    Test.assertMessage(
        !gate.consume(WatchUi.KEY_ESC),
        "Back without KEY_ESC must be treated as touch"
    );
    return true;
}

(:test)
function mainInputGateAcceptsPhysicalBack(logger as Test.Logger) as Boolean {
    var gate = new MainInputGate();
    gate.press(WatchUi.KEY_ESC);
    Test.assertMessage(
        gate.consume(WatchUi.KEY_ESC),
        "fresh KEY_ESC must classify Back as the lower button"
    );
    return true;
}

(:test)
function mainInputGateClearsReleasedKey(logger as Test.Logger) as Boolean {
    var gate = new MainInputGate();
    gate.press(WatchUi.KEY_ESC);
    gate.release(WatchUi.KEY_ESC);
    Test.assertMessage(
        !gate.consume(WatchUi.KEY_ESC),
        "released KEY_ESC must not classify a later right-swipe as a button"
    );
    return true;
}

(:test)
function mainInputGateConsumesMismatchedKey(logger as Test.Logger) as Boolean {
    var gate = new MainInputGate();
    gate.press(WatchUi.KEY_ENTER);
    Test.assertMessage(
        !gate.consume(WatchUi.KEY_ESC),
        "KEY_ENTER must not classify Back as the lower button"
    );
    Test.assertMessage(
        !gate.consume(WatchUi.KEY_ENTER),
        "a mismatched behavior must still clear the old key latch"
    );
    return true;
}

// Only the touch paths are driven here, and only on the main screen's delegate.
// Every path that reaches WatchUi.pushView or popView needs a real view stack
// under it, which the test runner does not have -- those are asserted against a
// live simulator in tests/input-behaviour.ps1 instead.
(:test)
function mainDelegateDefersTapToOnTap(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate(Rows.SCREEN_MAIN);
    Test.assertMessage(
        !delegate.onSelect(),
        "Select without KEY_ENTER must defer to the coordinate-bearing onTap"
    );
    return true;
}

// Back never exits the main screen any more, whatever raised it -- the firmware
// synthesizes a real KEY_ESC for a right swipe, so "was a key latched?" is a
// question onBack cannot answer honestly on this hardware. It consumes the
// event and arms the hint instead.
//
// The hint is asserted here rather than left to the eye because it is the only
// thing a Back now produces: if it stopped arming, a Back would be
// indistinguishable from a frozen app and nothing else in the suite would
// notice.
(:test)
function mainDelegateSwallowsBackAndArmsTheHint(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate(Rows.SCREEN_MAIN);
    var app = getApp();
    try {
        Test.assertMessage(
            delegate.onBack(),
            "Back must be consumed on the main screen, never exit"
        );
        Test.assertMessage(
            app.showsExitHint(),
            "a Back must arm the HOLD TO EXIT hint -- it is the only feedback there is"
        );
    } finally {
        // Take the hint down and stop its timer rather than leaving one of the
        // device's three armed for the rest of the run.
        app.hintCallback();
    }

    Test.assertMessage(!app.showsExitHint(), "the hint must come back down");
    return true;
}

// The SETTINGS screen answers a Back exactly as the main screen does, and that
// sameness is the assertion.
//
// It was not always so. The settings screen used to swallow a Back in silence,
// because its bottom band was a BACK button and a hint would have covered the
// control it described. ADR-0036 retired the button -- the upper button cycles
// the screens -- which freed the band and collapsed onBack to one path. A
// screen branch creeping back in here is the regression this catches: a wearer
// who brushes the glass mid-adjustment must be told what still works, and the
// held lower button works from this screen too.
(:test)
function settingsDelegateSwallowsBackAndArmsTheHint(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate(Rows.SCREEN_SETTINGS);
    var app = getApp();
    try {
        Test.assertMessage(
            delegate.onBack(),
            "Back must be consumed on the settings screen, never pop it"
        );
        Test.assertMessage(
            app.showsExitHint(),
            "a Back on the settings screen must arm the same hint the main screen arms"
        );
    } finally {
        app.hintCallback();
    }

    Test.assertMessage(!app.showsExitHint(), "the hint must come back down");
    return true;
}

// The hold-to-repeat arming logic, without a simulator: startRepeat and
// stopRepeat own the timer and nothing else, so they can run here without a
// Storage write. The stepping itself (onHold -> steps -> onRelease) is driven
// with a real touch-hold in tests/input-behaviour.ps1.
(:test)
function mainDelegateRepeatArmsAndDisarms(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate(Rows.SCREEN_MAIN);
    try {
        delegate.startRepeat(mainScreenHit(0, true));
        Test.assertMessage(delegate.isRepeating(), "startRepeat must arm the repeat");
        delegate.stopRepeat();
        Test.assertMessage(!delegate.isRepeating(), "stopRepeat must disarm it");

        // Re-arming replaces the previous timer rather than leaking it; the
        // device has three timers total and the cue owns one already.
        delegate.startRepeat(mainScreenHit(0, true));
        delegate.startRepeat(mainScreenHit(1, false));
        Test.assertMessage(delegate.isRepeating(), "re-arming must leave the repeat armed");
    } finally {
        delegate.stopRepeat();
    }
    return true;
}

// A missed onRelease must never leave a value running away on its own, so
// every other input path disarms the repeat -- these are the paths a finger
// or a button can actually take mid-hold.
(:test)
function mainDelegateAnyInputStopsTheRepeat(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate(Rows.SCREEN_MAIN);
    var hit = mainScreenHit(0, true);
    try {
        delegate.startRepeat(hit);
        delegate.onBack();      // swallowed now, whatever raised it
        Test.assertMessage(!delegate.isRepeating(), "a swallowed Back must stop the repeat");

        // onMenu is deliberately NOT driven here: it calls System.exit(), which
        // would end the test runner mid-suite. It stops the repeat on its way
        // out like every other handler, and tests/input-behaviour.ps1 is what
        // proves it against a real held button.

        delegate.startRepeat(hit);
        delegate.onSelect();
        Test.assertMessage(!delegate.isRepeating(), "Select must stop the repeat");

        delegate.startRepeat(hit);
        delegate.onNextPage();
        Test.assertMessage(!delegate.isRepeating(), "a vertical swipe must stop the repeat");
    } finally {
        delegate.stopRepeat();
        // onBack armed the hint on its way through; take it back down.
        getApp().hintCallback();
    }
    return true;
}
