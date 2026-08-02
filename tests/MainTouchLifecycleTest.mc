import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// The unit-test application shows its real initial View before test entries
// run, so this observes the master gate in its actual lifecycle context.
(:test)
function mainScreenStartsWithTouchDisabled(logger as Test.Logger) as Boolean {
    if (!(WatchUi has :getTouchEventsConfiguration)) {
        Test.assertMessage(
            false,
            "vivoactive5 must expose getTouchEventsConfiguration (API 5.2.0)"
        );
        return true;
    }

    var configuration = WatchUi.getTouchEventsConfiguration();
    Test.assertMessage(
        configuration[:enabled] == false,
        "main screen must start with touch events disabled"
    );
    return true;
}
