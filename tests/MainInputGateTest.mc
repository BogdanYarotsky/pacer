import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

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

(:test)
function mainDelegateDefersTapToOnTap(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate();
    Test.assertMessage(
        !delegate.onSelect(),
        "Select without KEY_ENTER must defer to the coordinate-bearing onTap"
    );
    return true;
}

(:test)
function mainDelegateSwallowsBackWithoutPhysicalKey(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate();
    Test.assertMessage(
        delegate.onBack(),
        "Back without KEY_ESC must be consumed as touch"
    );
    return true;
}

// The hold-to-repeat arming logic, without a simulator: startRepeat and
// stopRepeat own the timer and nothing else, so they can run here without a
// Storage write. The stepping itself (onHold -> steps -> onRelease) is driven
// with a real touch-hold in tests/input-behaviour.ps1.
(:test)
function mainDelegateRepeatArmsAndDisarms(logger as Test.Logger) as Boolean {
    var delegate = new candleDelegate();
    try {
        delegate.startRepeat(Layout.ACTION_EVERY_UP);
        Test.assertMessage(delegate.isRepeating(), "startRepeat must arm the repeat");
        delegate.stopRepeat();
        Test.assertMessage(!delegate.isRepeating(), "stopRepeat must disarm it");

        // Re-arming replaces the previous timer rather than leaking it; the
        // device has three timers total and the cue owns one already.
        delegate.startRepeat(Layout.ACTION_EVERY_UP);
        delegate.startRepeat(Layout.ACTION_POWER_DOWN);
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
    var delegate = new candleDelegate();
    try {
        delegate.startRepeat(Layout.ACTION_EVERY_UP);
        delegate.onBack();      // swipe-back arrives with no key latched
        Test.assertMessage(!delegate.isRepeating(), "a swallowed Back must stop the repeat");

        delegate.startRepeat(Layout.ACTION_EVERY_UP);
        delegate.onMenu();
        Test.assertMessage(!delegate.isRepeating(), "Menu must stop the repeat");

        delegate.startRepeat(Layout.ACTION_EVERY_UP);
        delegate.onSelect();
        Test.assertMessage(!delegate.isRepeating(), "Select must stop the repeat");

        delegate.startRepeat(Layout.ACTION_EVERY_UP);
        delegate.onNextPage();
        Test.assertMessage(!delegate.isRepeating(), "a vertical swipe must stop the repeat");
    } finally {
        delegate.stopRepeat();
    }
    return true;
}
