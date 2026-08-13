import Toybox.Lang;
import Toybox.Test;
// The test runner rejects configureTouchEvents(true), even from the foreground
// View. The platform state is therefore covered by the real input test; here we
// assert the app's own fresh-instance contract.
(:test)
function editorStartsLogicallyUnlocked(logger as Test.Logger) as Boolean {
    Test.assertMessage(
        !getApp().isTouchLocked(),
        "a fresh editor must not opt into touch lock"
    );
    return true;
}
