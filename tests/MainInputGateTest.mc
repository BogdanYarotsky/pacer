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
function mainDelegateDefersUnlockedTapToOnTap(logger as Test.Logger) as Boolean {
    var delegate = new pacerDelegate();
    Test.assertMessage(
        !delegate.onSelect(),
        "unlocked Select without KEY_ENTER must defer to coordinate-bearing onTap"
    );
    return true;
}

(:test)
function mainDelegateSwallowsBackWithoutPhysicalKey(logger as Test.Logger) as Boolean {
    var delegate = new pacerDelegate();
    Test.assertMessage(
        delegate.onBack(),
        "Back without KEY_ESC must be consumed as touch"
    );
    return true;
}
